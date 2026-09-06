library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_memory is
end entity;

architecture sim of tb_memory is
	signal clk      : std_logic := '0';
	signal we       : std_logic := '0';
	signal address  : std_logic_vector(12 downto 0) := (others => '0');
	signal data_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal data_out : std_logic_vector(31 downto 0);

begin
	clk <= not clk after 5 ns;

	dut : entity work.sram
		port map (
			clk      => clk,
			we       => we,
			a  => address,
			wd  => data_in,
			rd => data_out
		);

	stimulus : process
		procedure write_mem(constant addr : natural;
												constant value : std_logic_vector) is
		begin
			address <= std_logic_vector(to_unsigned(addr, address'length));
			data_in <= value;
			we <= '1';
			wait until rising_edge(clk);
			we <= '0';
			wait for 1 ns;
		end procedure;

		procedure read_check(constant addr : natural;
												 constant expected : std_logic_vector;
												 constant message : string) is
		begin
			address <= std_logic_vector(to_unsigned(addr, address'length));
			we <= '0';
			wait for 1 ns;
			assert data_out = expected report message severity error;
		end procedure;

		constant VALUE_A : std_logic_vector(31 downto 0) := x"12345678";
		constant VALUE_B : std_logic_vector(31 downto 0) := x"CAFEBABE";
	begin
		write_mem(16, VALUE_A);
		read_check(16, VALUE_A, "SRAM readback failed at address 16");

		write_mem(42, VALUE_B);
		read_check(42, VALUE_B, "SRAM readback failed at address 42");
		read_check(16, VALUE_A, "SRAM data was not retained at address 16");

		report "SRAM testbench completed successfully" severity note;
		wait;
	end process;
end architecture;
