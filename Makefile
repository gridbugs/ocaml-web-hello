build:
	dune build

run: build
	dune exec ./hello.exe

clean:
	dune clean

.PHONY: build run clean
