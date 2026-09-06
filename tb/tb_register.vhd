library ieee;
use ieee.std_logic_1164.all;

entity tb_register is
end entity tb_register;

architecture sim of tb_register is
    signal clk : std_logic := '0';
    signal a1, a2 : std_logic_vector(4 downto 0) := (others => '0');
    signal out1, out2 : std_logic_vector(31 downto 0);
    signal we : std_logic := '0';
    signal a3 : std_logic_vector(4 downto 0) := (others => '0');
    signal in3 : std_logic_vector(31 downto 0) := (others => '0');
begin
    clk <= not clk after 5 ns;

    dut: entity work.register_file
        port map (
            clk  => clk,
            a1   => a1,
            a2   => a2,
            out1 => out1,
            out2 => out2,
            we   => we,
            a3   => a3,
            in3  => in3
        );

    process
    begin
        -- Register zero must initially contain zero.
        a1 <= "00000";
        wait for 1 ns;
        assert out1 = x"00000000"
            report "Register 0 is not initialized to zero"
            severity error;

        -- Write register 1.
        a3 <= "00001";
        in3 <= x"00000010";
        we <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;

        -- Read register 1.
        we <= '0';
        a1 <= "00001";
        wait for 1 ns;
        assert out1 = x"00000010"
            report "Register 1 contains an incorrect value"
            severity error;

        -- Register zero must not be writable.
        a3 <= "00000";
        in3 <= x"FFFFFFFF";
        we <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;

        we <= '0';
        a1 <= "00000";
        wait for 1 ns;
        assert out1 = x"00000000"
            report "Register 0 was incorrectly modified"
            severity error;

        -- Verify the second read port.
        a2 <= "00001";
        wait for 1 ns;
        assert out2 = x"00000010"
            report "Second read port returned an incorrect value"
            severity error;

        report "Register file tests completed successfully"
            severity note;
        wait;
    end process;
end architecture sim;