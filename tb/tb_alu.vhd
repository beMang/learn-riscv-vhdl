library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu is
-- Testbenches do not have ports
end entity tb_alu;

architecture sim of tb_alu is

  -- Constants
  constant WIDTH : integer := 32;

  -- DUT Signals
  signal a, b     : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal op       : std_logic_vector(3 downto 0)       := (others => '0');
  signal result   : std_logic_vector(WIDTH-1 downto 0);
  signal zero     : std_logic;

begin

  -- Instantiate the Device Under Test (DUT)
  dut: entity work.alu
    port map (
      a      => a,
      b      => b,
      sel     => op,
      y => result,
      zero    => zero
    );

  -- Main Stimulus & Verification Process
  stim_proc: process
    
    -- Helper procedure (acts as a unit test runner)
    procedure check_alu(
      constant a_in, b_in : in integer;
      constant op_in     : in std_logic_vector(3 downto 0);
      constant expected  : in integer;
      constant test_name : in string
    ) is
    begin
      -- Apply Stimulus
      a  <= std_logic_vector(to_signed(a_in, WIDTH));
      b  <= std_logic_vector(to_signed(b_in, WIDTH));
      op <= op_in;
      
      -- Wait for propagation delay
      wait for 10 ns;
      
      -- Assertion Check
      assert (result = std_logic_vector(to_signed(expected, WIDTH)))
        report "FAIL [" & test_name & "]: Expected " & integer'image(expected) &
               " but got " & integer'image(to_integer(signed(result)))
        severity ERROR;

      -- Assertion Check for Zero Flag
      if expected = 0 then
        assert (zero = '1') 
          report "FAIL [" & test_name & "]: Zero flag should be '1'" 
          severity ERROR;
      else
        assert (zero = '0') 
          report "FAIL [" & test_name & "]: Zero flag should be '0'" 
          severity ERROR;
      end if;
    end procedure;

  begin
    report "--- Starting ALU Unit Tests ---";

    -- Test 1: Addition
    check_alu(a_in => 15, b_in => 10, op_in => "0000", expected => 25, test_name => "ADD Positive");
    check_alu(a_in => -5, b_in => 10, op_in => "0000", expected => 5,  test_name => "ADD Negative");

    -- Test 2: Subtraction
    check_alu(a_in => 20, b_in => 8,  op_in => "1000", expected => 12, test_name => "SUB Basic");

    -- Test 4 : 50 - 50 = 0, test for zero result
    check_alu(a_in => 50, b_in => 50, op_in => "1000", expected => 0, test_name => "SUB Zero Result");

    -- End Simulation Gracefully
    report "--- All ALU Unit Tests Completed ---";
    wait; -- Stop process execution
  end process;

end architecture sim;