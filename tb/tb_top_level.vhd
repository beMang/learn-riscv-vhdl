library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
end entity tb_top_level;

architecture simulation of tb_top_level is
	signal clk   : std_logic := '0';
	signal reset : std_logic := '1';
begin
	clk <= not clk after 5 ns;

	dut : entity work.top_level
		port map (
			clk   => clk,
			rst  => reset
		);

	stimulus : process
	begin
		-- Keep the processor in reset for two clock cycles.
		wait for 20 ns;
		reset <= '0';

		-- Allow enough time for the ADDI instruction to execute.
		for cycle in 1 to 300 loop
			wait until rising_edge(clk);
		end loop;

		report "Testbench completed after 300 clock cycles";
		wait;
	end process stimulus;
end architecture simulation;
