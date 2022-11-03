let sockaddr_to_string = function
  | Unix.ADDR_UNIX s -> s
  | ADDR_INET (addr, port) ->
      Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port

let serve ~port ~app ~initial_state =
  let sockfd = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let addr = Unix.ADDR_INET (Unix.inet_addr_any, port) in
  Unix.bind sockfd addr;
  Unix.listen sockfd 1;
  print_endline (Printf.sprintf "Listening on %s" (sockaddr_to_string addr));
  let rec loop state =
    let replyfd, cliaddr = Unix.accept sockfd in
    print_endline
      (Printf.sprintf "Got connection from %s" (sockaddr_to_string cliaddr));
    let response, new_state = app state in
    let length = String.length response in
    let num_chars_written = Unix.write_substring replyfd response 0 length in
    assert (num_chars_written == length);
    let () = Unix.close replyfd in
    loop new_state
  in
  loop initial_state

let make_response text =
  Printf.sprintf "HTTP/1.1 200 OK\nContent-Length: %d\n\n%s"
    (String.length text) text

let app state =
  let (`Count count) = state in
  let response = make_response (Printf.sprintf "<h1>Count: %d</h1>" count) in
  (response, `Count (count + 1))

let () = serve ~port:8000 ~app ~initial_state:(`Count 0)
