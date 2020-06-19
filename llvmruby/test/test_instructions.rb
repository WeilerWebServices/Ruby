require 'test/unit'
require 'llvm'

include LLVM

class InstructionTests < Test::Unit::TestCase

  def setup

    @assembly_byteswap=<<-EOF
    ; ModuleID = 'byteswap.bc'
    target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"
    target triple = "i386-apple-darwin9"

    define i32 @bswap(i32 %x) nounwind {
    entry:
    	%tmp3 = shl i32 %x, 24		; <i32> [#uses=1]
    	%tmp5 = shl i32 %x, 8		; <i32> [#uses=1]
    	%tmp6 = and i32 %tmp5, 16711680		; <i32> [#uses=1]
    	%tmp9 = lshr i32 %x, 8		; <i32> [#uses=1]
    	%tmp1018 = and i32 %tmp9, 65280		; <i32> [#uses=1]
    	%tmp7 = or i32 %tmp1018, %tmp3		; <i32> [#uses=1]
    	%tmp11 = or i32 %tmp7, %tmp6		; <i32> [#uses=1]
    	ret i32 %tmp11
    }
    EOF

  end

  def test_count_intructions_in_basic_block
    m = LLVM::Module.read_assembly(@assembly_byteswap)
    bswap = m.get_function("bswap")
    assert(bswap)

    bbs = bswap.get_basic_block_list
    assert_equal(1,bbs.size)
    b = bbs[0]
    assert_equal(8,b.size)

    expected_opcodes_in_bswap = ["shl", "shl", "and", "lshr", "and", "or", "or", "ret"]
    ins = b.get_instruction_list
    actual_opcodes_in_bswap = ins.map { |i| i.get_opcode_name}
    assert_equal(expected_opcodes_in_bswap, actual_opcodes_in_bswap)
    
    assert_kind_of(BinaryOperator, ins.first)
    assert_kind_of(ReturnInst, ins.last)
 
    f1, f2 = ins[0], ins[1]
    assert(!f1.may_read_from_memory?)
    assert(!f1.may_write_to_memory?)
    assert(!f1.identical_to?(f2))
    assert(f1.identical_to?(f1))
    assert(f1.same_operation_as?(f2))
    assert(f1.same_operation_as?(f1))
    assert(!f1.used_outside_of_block?(b))
  end

  def test_instruction_classes
    #m = LLVM::Module.read_assembly(@assembly_byteswap)
    #bswap = m.get_function('bswap')
  end

  def test_branch_instructions
    m = LLVM::Module.new('branch_instructions')
    ExecutionEngine.get(m)
    type = Type::function(MACHINE_WORD, [])

    f = m.get_or_insert_function("test_br", type)
    b1 = f.create_block
    b2 = f.create_block
    b3 = f.create_block
    b4 = f.create_block
    b5 = f.create_block

    b = b1.builder
    br_inst = b.br(b2)

    b = b2.builder
    cmp1 = b.icmp_sgt(-1.llvm, 1.llvm)
    cmp2 = b.icmp_slt(-1.llvm, 1.llvm)
    cond_br_inst = b.cond_br(cmp1, b3, b4)

    b = b3.builder
    b.return(23.llvm)

    b = b4.builder
    b.return(5.llvm)

    b = b5.builder
    ret_inst = b.return(1999.llvm)

    assert_kind_of(BranchInst, br_inst)
    assert(br_inst.unconditional?)
    assert(!br_inst.conditional?)
    assert_equal(1, br_inst.num_successors)
    assert_kind_of(BasicBlock, br_inst.get_successor(0))

    assert_kind_of(BranchInst, cond_br_inst)
    assert(cond_br_inst.conditional?)
    assert(!cond_br_inst.unconditional?)
    assert_kind_of(Value, cond_br_inst.condition)
    assert_equal(2, cond_br_inst.num_successors)
    assert_kind_of(BasicBlock, cond_br_inst.get_successor(1))

    assert_kind_of(ReturnInst, ret_inst)
    assert_equal(0, ret_inst.num_successors)

    cond_br_inst.condition = cmp2
    cond_br_inst.set_successor(0, b5)
    assert_equal(1999, ExecutionEngine.run_autoconvert(f))
  end
end
