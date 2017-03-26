require_relative 'matchers'

def merge(args)
  plsql.sc_service_op_steps.delete auditable_type: args[:auditable_type]
  plsql.sc_service_op_steps.insert args.merge({id: plsql.sc_service_op_steps_seq.nextval})
end

describe 'Setup' do
  context '' do
    it 'should be correct' do      
      merge({auditable_type: 'Success', branch_no: 1, step_no: 1, step_name: 'A', max_retries: 0, do_is_idempotent: 'N', do_has_requery: 'N', do_must_complete: 'N', do_is_optional: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'})
      result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: 'Success', po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
      expect(result).to be_correct
    end
    
    it 'should be incorrect when do_has_requery = Y and do_is_idempotent = Y' do      
      merge({auditable_type: 'Success', branch_no: 1, step_no: 1, step_name: 'A', max_retries: 0, do_is_idempotent: 'Y', do_has_requery: 'Y', do_must_complete: 'N', do_is_optional: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'})
      result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: 'Success', po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
      expect(result).to be_incorrect
    end    
  end  
end