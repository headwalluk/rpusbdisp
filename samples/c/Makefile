CC      ?= gcc
CFLAGS  ?= -O2 -Wall -Wextra

.PHONY: all clean

all: hello

hello: hello.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f hello
