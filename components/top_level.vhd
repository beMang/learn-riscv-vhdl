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
    signal pc : std_logic_vector(31 downto 0) := (others => '0'); -- program counter
    signal branch_pc : std_logic_vector(31 downto 0) := (others => '0'); -- address of fetched instruction
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
    signal immediate : std_logic_vector(31 downto 0); -- immediate value from instruction

    -- CONTROL SIGNALS
    signal IorD     : std_logic;
    signal MemWrite : std_logic;
    signal IRWrite  : std_logic;
    signal MemtoReg : std_logic_vector(1 downto 0);
    signal RegWrite : std_logic;
    signal PCWrite  : std_logic;
    signal PCSrc    : std_logic;
    signal PCEnable  : std_logic;
    signal Branch   : std_logic;
    signal BranchTaken : std_logic;
    signal ImmCtrl  : std_logic_vector(1 downto 0);

    -- ALU signals
    signal alu_op   : std_logic_vector(3 downto 0);
    signal alu_src_a: std_logic;
    signal alu_src_b: std_logic_vector(1 downto 0);
    signal alu_a    : std_logic_vector(31 downto 0);
    signal alu_b    : std_logic_vector(31 downto 0);
    signal alu_result: std_logic_vector(31 downto 0);
    signal zero     : std_logic;

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
            ImmCtrl => ImmCtrl,
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
    process(all)
    begin
        case MemtoReg is
            when "00" => -- ALU result
                reg_wd <= alu_out;
            when "01" => -- memory data
                reg_wd <= data;
            when "10" => -- PC + 4 (already +4 during fetch)
                reg_wd <= pc;
            when others =>
                reg_wd <= (others => '0');
        end case;
    end process;

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
    process(all)
        variable imm13 : std_logic_vector(12 downto 0);
        variable imm21 : std_logic_vector(20 downto 0);
        variable imm32 : std_logic_vector(31 downto 0);
        variable immb  : std_logic_vector(31 downto 0);
        variable immj  : std_logic_vector(31 downto 0);
    begin
        -- I-type immediate (12-bit sign-extended)
        imm32 := (31 downto 12 => ir(31)) & ir(31 downto 20);

        -- B-type immediate (13-bit sign-extended)
        imm13 := ir(31) &          -- Bit 12 (Sign)
                ir(7)  &          -- Bit 11
                ir(30 downto 25) & -- Bits 10..5
                ir(11 downto 8)  & -- Bits 4..1
                '0';              -- Bit 0 (Always 0)
        immb  := std_logic_vector(resize(signed(imm13), 32));

        -- J-type immediate (21-bit sign-extended)
        imm21 := ir(31)          & -- Bit 20 (Sign)
                ir(19 downto 12) & -- Bits 19..12
                ir(20)          & -- Bit 11
                ir(30 downto 21) & -- Bits 10..1
                '0';              -- Bit 0 (Always 0)
        immj  := std_logic_vector(resize(signed(imm21), 32));

        case ImmCtrl is
            when "00" => -- I-type
                immediate <= imm32;
            when "01" => -- J-type
                immediate <= immj;
            when "10" => -- B-type
                immediate <= immb;
            when others =>
                immediate <= (others => '0');
        end case;
    end process;

    -- Branch logic
    process(all)
        variable BranchTakenInternal : std_logic;
    begin
        PCEnable <= PCWrite or (Branch and BranchTaken);
        case ir(14 downto 13) is --fun3
            when "00" => -- BEQ/BNE
                BranchTakenInternal :=  zero;
            when "10" => -- BLT/BGE
                BranchTakenInternal := not zero;
            when "11" => -- BLTU/BGEU
                BranchTakenInternal := not zero;
            when others =>
                BranchTakenInternal := '0'; -- not implemented yet TODO
        end case;
        if ir(12) = '1' then -- BNE/BGE/BGEU
            BranchTaken <= not BranchTakenInternal;
        else
            BranchTaken <= BranchTakenInternal;
        end if;
    end process;

    -- ALU MUXes (this looks a bit sketchy, TODO : inspect)
    alu_a <= branch_pc when alu_src_a = '0' and alu_src_b = "01" else
             pc when alu_src_a = '0' else
             A_rd;
             
    process(all)
    begin
        case alu_src_b is
            when "00" => alu_b <= B_rd;
            when "01" => alu_b <= immediate;
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
            zero => zero -- not used for now, but will be for branch instructions
        );

    -- REGISTER UPDATE
    process(clk)
    begin
        if rising_edge(clk) then
            if IRWrite = '1' then
                ir <= rd_memory;
                branch_pc <= pc;
            end if;

            if PCEnable = '1' then
                case PCSrc is
                    when '0' => pc <= alu_result; -- ALU result
                    when '1' => pc <= alu_out;
                    when others => pc <= (others => '0');
                end case;
            end if;

            A_rd <= reg_rd1;
            B_rd <= reg_rd2;

            alu_out <= alu_result;
            data <= rd_memory;
        end if;
    end process;

end architecture rtl;
