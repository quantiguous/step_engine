require_relative 'matchers'

def create(args, del = true)
  plsql.sc_service_op_steps.delete auditable_type: args[:auditable_type]  if del 
  plsql.sc_service_op_steps.insert args.merge({id: plsql.sc_service_op_steps_seq.nextval})
end

describe 'Setup' do
  context '' do
    let(:auditable_type) { 'A' }
    let (:step) { {auditable_type: auditable_type, branch_no: 1, step_no: 1, step_name: 'A', max_retries: 0, do_is_idempotent: 'N', do_has_requery: 'N', do_must_complete: 'N', do_is_optional: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'} }

    context 'when the setup is good' do
      it 'should be correct' do      
        create(step)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_correct
      end
    end
    
    context 'when do_has_rqeuery = Y and do_is_idempotent = Y' do
      let (:step) { super().merge({do_is_idempotent: 'Y', do_has_requery: 'Y'}) }
      it 'should be incorrect' do
        create(step)        
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end
    
    context 'when do_must_complete = Y and do_is_optional = Y' do
      let (:step) { super().merge({do_must_complete: 'Y', do_is_optional: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end

    context 'when do_is_optional = Y and not the last step of first branch' do
      let (:step) { super().merge({do_is_optional: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        create(step.merge(step_no: 2), false)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end


    context 'when do_is_optional = Y and not the last step of last branch' do
      let (:step) { super().merge({do_is_optional: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        create(step.merge(branch_no: 2, step_no: 2, do_is_optional: 'Y'), false)
        create(step.merge(branch_no: 2, step_no: 3), false)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end

    context 'when do_is_optional = Y and the last step of last branch' do
      let (:step) { super().merge({do_is_optional: 'Y'}) }
      it 'should be correct' do
        create(step)
        create(step.merge(branch_no: 2, step_no: 2, do_is_optional: 'N'), false)
        create(step.merge(branch_no: 2, step_no: 3), false)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_correct
      end
    end
    
    context 'when skip_reveral = Y and reversal_has_requery = Y' do
      let (:step) { super().merge({skip_reversal: 'Y', reversal_has_requery: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end    
    
    context 'when skip_reveral = Y and reversal_is_idempotent = Y' do
      let (:step) { super().merge({skip_reversal: 'Y', reversal_is_idempotent: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end    

    context 'when reversal_has_requery = Y and reversal_is_idempotent = Y' do
      let (:step) { super().merge({reversal_has_requery: 'Y', reversal_is_idempotent: 'Y'}) }
      it 'should be incorrect' do
        create(step)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end    
    
    context 'when a step is skipped' do
      it 'should be incorrect' do
        create(step)
        create(step.merge(step_no: 3), false)
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end    

    context 'when a wait internval is not a multiple of 1000' do
      it 'should be incorrect' do
        create(step.merge(ms_to_nxt_step: 1023))
        result = plsql.pk_qg_sc_step_engine.verify_setup(pi_auditable_type: auditable_type, po_fault_code: nil, po_fault_subcode: nil, po_fault_reason: nil)
        expect(result).to be_incorrect
      end
    end    
    
  end
end