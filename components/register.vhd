library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk : in std_logic;

        -- Input addresses (5 bits for 32 registers of 32 bits each)
        a1 : in std_logic_vector(4 downto 0);
        a2 : in std_logic_vector(4 downto 0);

        out1: out std_logic_vector(31 downto 0);
        out2: out std_logic_vector(31 downto 0);

        we : in std_logic; -- Write Enable
        a3 : in std_logic_vector(4 downto 0); -- Write Address
        in3 : in std_logic_vector(31 downto 0) -- Write Data
    );
end entity register_file;

architecture rtl of register_file is
    type reg_array is array (31 downto 0) of std_logic_vector(31 downto 0);
    signal regs : reg_array := (others => (others => '0')); -- init to zero
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' and a3 /= "00000" then -- Prevent writing to register 0
                regs(to_integer(unsigned(a3))) <= in3;
            end if;
        end if;
    end process;

    out1 <= regs(to_integer(unsigned(a1)));
    out2 <= regs(to_integer(unsigned(a2)));
end architecture rtl;