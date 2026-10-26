# CPU Debug Log

## 2026-10-23 

### Symptom
- CLK30026 - Missing Clock Assignment
- ![Quartus missing-clock warning](debug_screenshots/missing_clock_assignment.png) 

### Root Cause
- Initially, 'take_branch' was only modified when 'stall' = 0. When 'stall' = 1, 'take_branch' was not assigned to anything so Quartus had to create a latch to hold its previous value.
- An unintended latch was created for 'take_branch' signal with 'stall' signal being the enable signal. Quartus treats enable signal as a clock input when it's not supposed to be.
- Affected module/signal: the whole cpu system.

### Fix
- Assign 'take_branch' to a default value at the end of the always block without relying on changing it based on 'stall'. 

### Verification
- Run the timing analyzer again and see the error is gone.

### Lesson Learned
- How can I avoid or detect this next time: Assign every signal to a default value so no unintended latch is created.  

### Related Commit
- Commit:

---

### Symptom
- Unconstrained Input Ports
- ![Quartus missing-clock warning](debug_screenshots/unconstrained_input.png) 

### Root Cause
- Switches can change at any time relative to the clock edge but initially, no timing constrain was set for it.
- Affected module/signal: the whole cpu system.

### Fix
- set_false_path -from [get_ports {SW[*]}], to let Quartus know to exclude all timing paths starting at the SW input ports in the timing analysis. 

### Verification
- Run the timing analyzer again and see the error is gone.

### Lesson Learned
- How can I avoid or detect this next time: Set false path timing constrains for inputs or outputs that need no timing requirement.  

### Related Commit
- Commit:

---

### Symptom
- Unconstrained Output Ports
- ![Quartus missing-clock warning](debug_screenshots/unconstrained_output.png) 

### Root Cause
- The LEDR doesn't need to satisfy the timing requirement of delivering its signal to any external devices at any time relative to the clock edge but initially, no timing constrain was set for it.
- Affected module/signal: the whole cpu system.

### Fix
- set_false_path -to [get_ports {LEDR[*]} ], to let Quartus know to exclude all timing paths starting at the LEDR output ports in the timing analysis. 

### Verification
- Run the timing analyzer again and see the error is gone.

### Lesson Learned
- How can I avoid or detect this next time: Set false path timing constrains for inputs or outputs that need no timing requirement.  

### Related Commit
- Commit: