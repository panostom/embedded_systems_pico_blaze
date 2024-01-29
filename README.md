# embedded_systems_pico_blaze
This is the sequence design of the data acquisition in embedded repo. For this design the read FSM has been replaced with Picoblaze, a soft processor core microcontroller.
# Design description
The design of the system remains the same apart from the replace of the read FSM with Picoblaze microcontroller, for reading from ram and calculating the average.
1. During the new design and simulating I noticed a malfunction of the signals from the design coming from the write FSM. It appeared that the two states that have been previously designed and worked were not enough for this design. The simulation was showing that the Picoblaze could not get the first value from the BRAM because it was already overwritten by the next value coming from the median output. Addition of an empty state in FSM write to create a delay was necessary to solve the problem.
2. In order to “jump start” the Picoblaze was necessary to write an interrupt routine in assembly for reading and calculating.
3. All the necessary design requirements for connecting the ports are briefly described in Xilinx manual and design as required.
* 4:1 input multiplexer
* 1:4 output demultiplexer
4. Next was the design of the task that was checking the average produced by the Picoblaze and give the appropriate messages.
* For this requirement I made first a task that gets one argument and is calculating the sum produced for every median output. This task is called after the initial begin in the test bench during negative clock when data_av_ai signal is low.
* The second task that has been designed gets two arguments, the first argument gets the average value from the Picoblaze and the second gets the sum from the previous task, divides it by 8 and compares it to the original value.

5. The last requirement for the design was the assertion structure that gives message when the interrupt signal is enabled in Picoblaze. For this design I tried two different approaches.
* The first one by checking when the control_rd (output signal that enables the interrupt) signal coming from the fsm_wr is high to check at the same clock cycle if the interrupt_req_i is high by using the overlapping operator ( |-> ).
