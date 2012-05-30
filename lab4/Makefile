default:
	iverilog -Wall -o mipstest *.v

test: default
	./mipstest -lxt <<< "finish"

wave: test
	gtkwave MIPStest.lxt &

clean:
	rm -f mipstest MIPStest.lxt
