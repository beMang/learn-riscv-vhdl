library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Control unit for processor
entity control_unit is
    port (
        clk : in std_logic;
        opcode : in std_logic_vector(6 downto 0); -- riscv opcode
        fun3 : in std_logic_vector(2 downto 0); -- riscv funct3
        fun7 : in std_logic_vector(6 downto 0); -- riscv funct7

        -- Outputs to datapath
        IorD : out std_logic; -- 0: PC, 1: ALU result
        MemWrite : out std_logic; -- 1: write to memory
        IRWrite : out std_logic; -- 1: write to instruction register
        MemtoReg: out std_logic; -- 0: ALU result, 1: memory data
        RegWrite : out std_logic; -- 1: write to register file
        PCWrite : out std_logic; -- 1: write to PC
        Branch : out std_logic; -- 1: branch taken
        PCSrc : out std_logic; -- 0: ALU result, 1: ALU out (one register further)

        --Alu :
        alu_op : out std_logic_vector(3 downto 0);
        alu_src_a : out std_logic; -- 0: PC, 1: register
        alu_src_b : out std_logic_vector(1 downto 0) -- 00: register, 01: immediate, 10: 4
    );
end entity control_unit;

architecture rtl of control_unit is
    type state_type is (S0, S1, S2, S3); -- For simple instruction, only fetch, decode, execute and writeback to register is needed (other states will be added for more complex instructions)
    signal state : state_type := S0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when S0 => -- Fetch instruction
                    IorD <= '0'; -- PC
                    alu_src_a <= '0'; -- PC
                    alu_src_b <= "10"; -- 4
                    alu_op <= "0000"; -- add
                    PCSrc <= '0';
                    IRWrite <= '1'; -- write to instruction register
                    PCWrite <= '1'; -- write to PC

                    MemWrite <= '0'; -- no write to memory
                    MemtoReg <= '0'; -- no write to register file
                    RegWrite <= '0'; -- no write to register file
                    Branch <= '0'; -- no branch
                    state <= S1; -- next state is decode
                when S1 => -- Decode instruction (compute eventual branch address)
                    alu_src_a <= '0'; -- PC
                    alu_src_b <= "11"; -- immediate x 4 (see if this is risc-v compliant)
                    alu_op <= "0000"; -- add

                    IRWrite <= '0'; -- no write to instruction register
                    PCWrite <= '0'; -- no write to PC
                    MemWrite <= '0'; -- no write to memory
                    MemtoReg <= '0'; -- no write to register file
                    RegWrite <= '0'; -- no write to register file
                    Branch <= '0'; -- no branch

                    case opcode is
                        when "0010011" => -- OP-IMM
                            state <= S2;
                        when others =>
                            state <= S0; -- default to fetch
                    end case;
                when S2 => -- Execute instruction
                    alu_src_a <= '1'; -- register
                    case opcode is
                        when "0010011" => -- OP-IMM
                            case fun3 is
                                when "000" => -- ADDI
                                    alu_src_b <= "01"; -- immediate
                                    alu_op <= "0000"; -- add
                                when "010" => -- SLTI
                                    alu_src_b <= "01"; -- immediate
                                    alu_op <= "0010"; -- set less than
                                when "011" => -- SLTIU
                                    alu_src_b <= "01"; -- immediate
                                    alu_op <= "0011"; -- set less than unsigned
                                when others =>
                                    alu_src_b <= "01"; -- immediate
                                    alu_op <= "0000"; -- add (default)
                            end case;
                        when others =>
                            alu_src_b <= "00"; -- register (default)
                            alu_op <= "0000"; -- add (default)
                    end case;

                    IRWrite <= '0'; -- no write to instruction register
                    PCWrite <= '0'; -- no write to PC
                    MemWrite <= '0'; -- no write to memory
                    MemtoReg <= '0'; -- no write to register file
                    RegWrite <= '0'; -- no write to register file
                    Branch <= '0'; -- no branch
                    state <= S3; -- next state is writeback to register
                when S3 => -- Writeback to register
                    MemtoReg <= '0'; -- ALU result
                    RegWrite <= '1'; -- write to register file

                    IorD <= '0'; -- PC (default)
                    alu_src_a <= '0'; -- PC (default)
                    alu_src_b <= "10"; -- 4 (default)
                    alu_op <= "0000"; -- add (default)
                    PCSrc <= '0'; -- ALU result (default)

                    IRWrite <= '0'; -- no write to instruction register
                    PCWrite <= '0'; -- no write to PC
                    MemWrite <= '0'; -- no write to memory
                    Branch <= '0'; -- no branch

                    state <= S0; -- next state is fetch
                when others =>
                    state <= S0; -- default to fetch
            end case;
        end if;
    end process;
end architecture rtl;