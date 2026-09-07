library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 32 bits ALU
-- 4 bits of sel => 16 possible operations
entity alu is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0);
        y : out std_logic_vector(31 downto 0);
        zero : out std_logic
    );
end entity alu;

architecture rtl of alu is
begin
    process(a, b, sel)
        variable result : std_logic_vector(31 downto 0);
    begin
        case sel is
            when "0000" => -- ADD
                result := std_logic_vector(signed(a) + signed(b));
            when "1000" => -- SUB
                result := std_logic_vector(signed(a) - signed(b));
            when "0010" => -- SLT
                if signed(a) < signed(b) then
                    result := (31 downto 1 => '0') & '1';
                else
                    result := (others => '0');
                end if;
            when "0011" => -- SLTU
                if unsigned(a) < unsigned(b) then
                    result := (31 downto 1 => '0') & '1';
                else
                    result := (others => '0');
                end if;
            when "0100" => -- XOR
                result := a xor b;
            when "0110" => -- OR
                result := a or b;
            when "0111" => -- AND
                result := a and b;
            when "1001" => -- SLL
                result := std_logic_vector(shift_left(unsigned(a), to_integer(unsigned(b(4 downto 0)))));
            when "0101" => -- SRL
                result := std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(b(4 downto 0)))));
            when "1101" => -- SRA
                result := std_logic_vector(shift_right(signed(a), to_integer(unsigned(b(4 downto 0)))));
            when others =>
                result := (others => '0'); -- Default case
        end case;

        y <= result;
        -- Set zero flag
        if result = (result'range => '0') then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;
end architecture rtl;