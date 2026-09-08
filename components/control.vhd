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
        MemtoReg: out std_logic_vector(1 downto 0); -- 00: ALU result, 01: memory data, 10: PC + 4
        RegWrite : out std_logic; -- 1: write to register file
        PCWrite : out std_logic; -- 1: write to PC
        Branch : out std_logic; -- 1: branch taken
        PCSrc : out std_logic; -- 0: ALU result, 1: ALU out (one register further)
        ImmCtrl : out std_logic_vector(1 downto 0); -- 00: I-type, 01: S-type, 10: B-type, 11: U-type

        --Alu :
        alu_op : out std_logic_vector(3 downto 0);
        alu_src_a : out std_logic; -- 0: PC, 1: register
        alu_src_b : out std_logic_vector(1 downto 0) -- 00: register, 01: immediate, 10: 4
    );
end entity control_unit;

architecture rtl of control_unit is
    type state_type is (S0, S1, S2, S3, SB, JAL, MemAdr, MWS, MRS, MWB); -- For simple instruction, only fetch, decode, execute and writeback to register is needed (other states will be added for more complex instructions)
    signal current_state, next_state : state_type := S0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(all)
    begin
        case current_state is
            when S0 => -- Fetch instruction
                IorD <= '0'; -- PC
                alu_src_a <= '0'; -- PC
                alu_src_b <= "10"; -- 4
                alu_op <= "0000"; -- add
                PCSrc <= '0';
                IRWrite <= '1'; -- write to instruction register
                PCWrite <= '1'; -- write to PC

                MemWrite <= '0'; -- no write to memory
                MemtoReg <= "00"; -- no write to register file
                RegWrite <= '0'; -- no write to register file
                Branch <= '0'; -- no branch
                next_state <= S1; -- next state is decode
            when S1 => -- Decode instruction (compute eventual branch address)
                alu_src_a <= '0'; -- PC
                alu_src_b <= "01"; -- immediate
                alu_op <= "0000"; -- add

                IRWrite <= '0'; -- no write to instruction register
                PCWrite <= '0'; -- no write to PC
                MemWrite <= '0'; -- no write to memory
                RegWrite <= '0'; -- no write to register file
                Branch <= '0'; -- no branch

                case opcode is
                    when "0110011" | "0010011" => -- OP or OP-IMM
                        next_state <= S2;
                    when "1100011" => -- BRANCH
                        next_state <= SB;
                        ImmCtrl <= "10"; -- B-type branch
                    when "1101111" => -- JAL
                        ImmCtrl <= "01"; -- J-type jump
                        next_state <= JAL;
                    when "0100011" | "0000011"=> -- STORE/LOAD
                        next_state <= MemAdr;
                        if opcode(5) = '1' then
                            ImmCtrl <= "11"; -- S-type for STORE
                        else
                            ImmCtrl <= "00"; -- I-type for LOAD
                        end if;
                    when others =>
                        next_state <= S0; -- default to fetch
                end case;
            when S2 => -- Execute instruction
                alu_src_a <= '1'; -- register
                case opcode is
                    when "0110011" => -- OP
                        alu_src_b <= "00"; -- register
                        case fun3 is
                            when "000" => -- ADD/SUB
                                alu_op <= fun7(5) & "000"; -- add/sub
                            when "010" => -- SLT
                                alu_op <= "0010"; -- set less than
                            when "011" => -- SLTU
                                alu_op <= "0011"; -- set less than unsigned
                            when "100" => -- XOR
                                alu_op <= "0100"; -- xor
                            when "110" => -- OR
                                alu_op <= "0110"; -- or
                            when "111" => -- AND
                                alu_op <= "0111"; -- and
                            when "001" => -- SLL
                                alu_op <= "1001"; -- shift left logical
                            when "101" => -- SRL/SRA
                                alu_op <= fun7(5) & "101"; -- shift right logical/arithmetic
                            when others =>
                                alu_op <= "0000"; -- add (default)
                        end case;
                    when "0010011" => -- OP-IMM
                        alu_src_b <= "01"; -- immediate
                        ImmCtrl <= "00"; -- I-type immediate
                        case fun3 is
                            when "000" => -- ADDI
                                alu_op <= "0000"; -- add
                            when "010" => -- SLTI
                                alu_op <= "0010"; -- set less than
                            when "011" => -- SLTIU
                                alu_op <= "0011"; -- set less than unsigned
                            when "100" => -- XORI
                                alu_op <= "0100"; -- xor
                            when "110" => -- ORI
                                alu_op <= "0110"; -- or
                            when "111" => -- ANDI
                                alu_op <= "0111"; -- and
                            when "001" => -- SLLI
                                alu_op <= "1001"; -- shift left logical
                            when "101" => -- SRLI/SRAI
                                alu_op <= fun7(5) & "101"; -- shift right logical/arithmetic
                            when others =>
                                alu_op <= "0000"; -- add (default)
                        end case;
                    when others =>
                        alu_src_b <= "00"; -- register (default)
                        alu_op <= "0000"; -- add (default)
                end case;

                IRWrite <= '0'; -- no write to instruction register
                PCWrite <= '0'; -- no write to PC
                MemWrite <= '0'; -- no write to memory
                RegWrite <= '0'; -- no write to register file
                Branch <= '0'; -- no branch
                next_state <= S3; -- next state is writeback to register
            when S3 => -- Writeback to register
                MemtoReg <= "00"; -- ALU result
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

                next_state <= S0; -- next state is fetch
            when SB => -- Branch instruction
                alu_src_a <= '1'; -- register
                alu_src_b <= "00"; -- register
                PCSrc <= '1'; -- ALU out (one register further)
                Branch <= '1'; -- branch taken
                case fun3 is
                    when "000" | "001" =>
                        alu_op <= "1000"; -- subtract for equality comparison
                    when "100" | "101" =>
                        alu_op <= "0010"; -- SLT for signed comparison
                    when "110" | "111" =>
                        alu_op <= "0011"; -- SLTU for unsigned comparison
                    when others =>
                        alu_op <= "0000"; -- add (default)
                end case;

                IRWrite <= '0'; -- no write to instruction register
                PCWrite <= '0'; -- no write to PC
                MemWrite <= '0'; -- no write to memory
                RegWrite <= '0'; -- no write to register file
                next_state <= S0; -- next state is fetch
            when JAL => -- JAL instruction
                PCSrc <= '1'; -- AlU out (to take adress computed during decode)
                PCWrite <= '1'; -- write to PC
                RegWrite <= '1'; -- write to register file
                MemtoReg <= "10";
                next_state <= S0; -- next state is fetch
            when MemAdr => -- Memory address computation for LOAD/STORE
                alu_src_a <= '1';
                alu_src_b <= "01"; -- immediate
                alu_op <= "0000"; -- add

                IRWrite <= '0'; -- no write to instruction register
                PCWrite <= '0'; -- no write to PC
                MemWrite <= '0'; -- no write to memory
                RegWrite <= '0'; -- no write to register file

                if opcode(5) = '1' then -- STORE
                    next_state <= MWS;
                else -- LOAD
                    next_state <= MRS;
                end if;
            when MWS => -- Memory write for STORE
                IorD <= '1';
                MemWrite <= '1';
                IRWrite <= '0'; -- no write to instruction register
                next_state <= S0;
            when MRS =>
                IorD <= '1';
                MemWrite <= '0';
                IRWrite <= '0'; -- no write to instruction register
                next_state <= MWB; -- next state is from memory writeback to register
            when MWB =>
                MemtoReg <= "01"; -- memory data
                RegWrite <= '1'; -- write to register file
                IorD <= '0'; -- PC (default)
                next_state <= S0; -- next state is fetch
            when others =>
                next_state <= S0; -- default to fetch
        end case;
    end process;
end architecture rtl;