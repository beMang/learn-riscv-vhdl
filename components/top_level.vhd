library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
    port (
        clk : in std_logic;
        rst : in std_logic -- not used for now
    );
end entity top_level;

architecture rtl of top_level is

    -- REGISTERS
    signal pc : std_logic_vector(31 downto 0); -- program counter
    signal ir : std_logic_vector(31 downto 0); -- instruction register
    signal data : std_logic_vector(31 downto 0); -- data from memory
    signal alu_out : std_logic_vector(31 downto 0); -- ALU output
    signal A_rd : std_logic_vector(31 downto 0); -- A output of register, after one clock cycle delay
    signal B_rd : std_logic_vector(31 downto 0); -- B output of register, after one clock cycle delay
    
    -- INTERCONNECT
    signal rd_memory : std_logic_vector(31 downto 0); -- data read from memory
    signal reg_rd1 : std_logic_vector(31 downto 0); -- register file read data 1
    signal reg_rd2 : std_logic_vector(31 downto 0); -- register file read data 2
    signal reg_wd : std_logic_vector(31 downto 0); -- register file write data
    signal imm32 : std_logic_vector(31 downto 0); -- immediate value extended to 32 bits

    -- CONTROL SIGNALS
    signal IorD     : std_logic;
    signal MemWrite : std_logic;
    signal IRWrite  : std_logic;
    signal MemtoReg : std_logic;
    signal RegWrite : std_logic;
    signal PCWrite  : std_logic;
    signal Branch   : std_logic;
    signal PCSrc    : std_logic;

    -- ALU signals
    signal alu_op   : std_logic_vector(3 downto 0);
    signal alu_src_a: std_logic;
    signal alu_src_b: std_logic_vector(1 downto 0);
    signal alu_a    : std_logic_vector(31 downto 0);
    signal alu_b    : std_logic_vector(31 downto 0);
    signal alu_result: std_logic_vector(31 downto 0);

    -- Memory Address Mux
    signal mem_addr : std_logic_vector(12 downto 0);

begin
    -- CONTROL UNIT
    ctrl_unit : entity work.control_unit
        port map (
            clk => clk,
            opcode => ir(6 downto 0),
            fun3 => ir(14 downto 12),
            fun7 => ir(31 downto 25),

            IorD => IorD,
            MemWrite => MemWrite,
            IRWrite => IRWrite,
            MemtoReg => MemtoReg,
            RegWrite => RegWrite,
            PCWrite => PCWrite,
            Branch => Branch,
            PCSrc => PCSrc,
            alu_op => alu_op,
            alu_src_a => alu_src_a,
            alu_src_b => alu_src_b
        );
    
    -- INSTRUCTION/DATA MEMORY
    mem_addr <= pc(12 downto 0) when IorD = '0' else alu_out(12 downto 0);
    
    memory : entity work.sram
        port map (
            clk => clk,
            we => MemWrite,
            a => mem_addr,
            wd => alu_b,
            rd => rd_memory
        );

    -- REGISTER FILE
    reg_wd <= data when MemtoReg = '1' else alu_out;

    reg_file : entity work.register_file
        port map (
            clk => clk,
            a1 => ir(19 downto 15), -- rs1
            a2 => ir(24 downto 20), -- rs2
            out1 => reg_rd1,
            out2 => reg_rd2,
            we => RegWrite,
            a3 => ir(11 downto 7), -- rd
            in3 => reg_wd
        );

    -- IMMEDIATE GENERATOR (really simple for now, maybe more complex later)
    imm32 <= (31 downto 12 => ir(31)) & ir(31 downto 20);

    -- ALU MUXes
    alu_a <= pc when alu_src_a = '0' else A_rd;
    process(all)
    begin
        case alu_src_b is
            when "00" => alu_b <= B_rd;
            when "01" => alu_b <= imm32;
            when "10" => alu_b <= x"00000004"; -- 4 for PC increment
            when others => alu_b <= (others => '0');
        end case;
    end process;

    -- ALU
    alu : entity work.alu
        port map (
            a => alu_a,
            b => alu_b,
            sel => alu_op,
            y => alu_result,
            zero => open -- not used for now, but will be for branch instructions
        );

    -- REGISTER UPDATE
    process(clk)
    begin
        if rising_edge(clk) then
            if IRWrite = '1' then
                ir <= rd_memory;
            end if;

            if PCWrite = '1' then
                pc <= alu_out;
            end if;

            A_rd <= reg_rd1;
            B_rd <= reg_rd2;

            alu_out <= alu_result;
            data <= rd_memory;
        end if;
    end process;

end architecture rtl;
