library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity sram is
    port (
        clk : in std_logic;
        we : in std_logic;
        a : in std_logic_vector(12 downto 0);
        wd : in std_logic_vector(31 downto 0);
        rd : out std_logic_vector(31 downto 0)
    );
end entity sram;

architecture rtl of sram is
    type mem_array is array (0 to 2047) of std_logic_vector(31 downto 0);

    impure function load_program return mem_array is
        file program_file : text open read_mode is "aux/program.hex";
        variable memory_image : mem_array := (others => x"00000013");
        variable input_line : line;
        variable instruction : std_logic_vector(31 downto 0);
        variable prefix : string(1 to 2);
        variable address : natural := 0;
    begin
        while not endfile(program_file) and address < memory_image'length loop
            readline(program_file, input_line);
            read(input_line, prefix);
            hread(input_line, instruction);
            memory_image(address) := instruction;
            address := address + 1;
        end loop;
        return memory_image;
    end function;

    signal mem : mem_array := load_program;

    signal word_address : integer range 0 to 2047;
begin
    word_address <= to_integer(unsigned(a(12 downto 2)));

    -- Sync write
    process(clk)
    begin
        if rising_edge(clk)  and we = '1' then
            mem(word_address) <= wd;
        end if;
    end process;

    -- Async read
    rd <= mem(word_address);
end architecture rtl;
