# Test Log

## 2026-10-25
- Test [basic_isa_selftest_verilog.txt](basic_isa_selftest_verilog). All passed!!!
- Test [forwarding_test_verilog.txt](forwarding_test_verilog.txt). All passed!!!

## Nov 1
- Test slow_data_memory, passed.
- Test slow_instruction_memory, passed.
- Test I_cache, nasty bug: initially reset all tags to be 0 but forgot to update slot_tag when new valid slot gets cached, and then when test for each slot, only do tag = 0 , so tag matches so it doesnt stall, but when new slot with different taag gets cached, tag mismatches after it done cache even tho it should match because tag slot always stay at 0 instead of updating. I_cache passed now.
- Test I-cache system, passed most cases, still testing.

## Nov3
-In load or store operation where writing back first is needed,forgot to give memory address that the cpu is requesting, instead kept the writing old address which is wrong.
- d_cache alone , all passed

## Nov16
- When designing DMA, I assume that memory will capture new write data right after it finishes writing old data in a burst. Then I put on the new data right after it announces finishing writing old data. That is not correct since I didnt have memory_ready to agree on the handshake. I Learnt that my design should be clearer and accomodate possible changes in the future. 