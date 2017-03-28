RSpec::Matchers.define :be_initialized do      
  match do |response|
    @record = StepHelper.fetch(response[:auditable_type], response[:auditable_id])
    expect(@record[:txn_status]).to eq('NEW')
    expect(@record[:current_step_no]).to eq(1)
    expect(@record[:current_step_action]).to eq('DO')
    expect(@record[:current_step_status]).to eq('DOING')
    expect(@record[:attempt_cnt]).to eq(0)
    expect(@record[:switch_branch_no]).to be_nil
    expect(@record[:next_step_action_at]).to_not be_nil
    expect(@record[:in_debug]).to eq(response[:start_in_debug])
    expect(@record[:is_paused]).to eq('N')
    
    expect(response[:fault_code]).to be_nil
    expect(response[:fault_reason]).to be_nil
  end
  
  failure_message do |response|
      "expected record to be initialized instead of #{response} with data: #{@record}"
  end  
end  

RSpec::Matchers.define :not_complete do
  match do |response|
    expect(response[:fault_code]).to eq(@fault_code)
    expect(response[:fault_reason]).to_not be_nil
  end
  
  chain :with_not_acceptible do
    @fault_code = 'ns:E406'
  end  
  
  failure_message do |response|
      "expected result to be incorrect instead of #{response}"
  end
end  

RSpec::Matchers.define :be_do do
  match do |response|
    expect(response[:current_step_action]).to eq('DO')
    expect(response[:is_paused]).to eq('N')
  end
  
  chain :with_not_acceptible do
    @fault_code = 'ns:E406'
  end  
  
  failure_message do |response|
      "expected result to have step_action DO instead of #{response}"
  end
end  



class StepHelper
  def self.make_service_code(auditable_type)
    'SVC_' + auditable_type
  end
  def self.make_op_name(auditable_type)
    'OP_' + auditable_type
  end
  
  def self.setup(args)
    auditable_type = args[0][:auditable_type]
    
    service_code = make_service_code(auditable_type)
    op_name = make_op_name(auditable_type)
    
    plsql.sc_services.delete code: service_code
    plsql.sc_services.insert ({id: plsql.sc_services_seq.nextval, code: service_code, name: "name #{service_code}"})
    service_id = plsql.select_one("select id from sc_services where code = '#{service_code}'")

    plsql.sc_service_ops.delete auditable_type: auditable_type
    plsql.sc_service_ops.insert ({id: plsql.sc_service_ops_seq.nextval, sc_service_id: service_id, op_name: op_name, auditable_type: auditable_type})
    
    plsql.sc_service_op_steps.delete auditable_type: auditable_type
    args.each_with_index do |step, i|
      plsql.sc_service_op_steps.insert step.merge({id: plsql.sc_service_op_steps_seq.nextval, step_no: i+1})
    end
    
    plsql.sc_pending_txns.delete auditable_type: auditable_type
  end
  
  def self.fetch(auditable_type, auditable_id)
    plsql.select(:first, "select * from sc_pending_txns where auditable_type = '#{auditable_type}' and auditable_id = #{auditable_id}")
  end
  
  def self.initialize(auditable_type, auditable_id, start_in_debug = 'N')
    plsql_result = plsql.pk_qg_sc_step_helper.initialize(
      pi_auditable_type: auditable_type, 
      pi_auditable_id: auditable_id,
      pi_start_in_debug: start_in_debug,
      po_fault_code: nil, 
      po_fault_subcode: nil, 
      po_fault_reason: nil)
      
      result = {}
      result[:auditable_type] = auditable_type
      result[:auditable_id] = auditable_id
      result[:start_in_debug] = start_in_debug
      result[:fault_code] = plsql_result[:po_fault_code]
      result[:fault_subcode] = plsql_result[:po_fault_subcode]
      result[:fault_reason] = plsql_result[:po_fault_reason]
    
      result    
  end

  def self.get_pending_txns(auditable_type)
    result = {}    
    plsql.pk_qg_sc_step_helper.get_pending_txns(
      pi_service_code: make_service_code(auditable_type), 
      pi_op_name: make_op_name(auditable_type)) do |c|
         result = c[:cursname].fetch_hash
      end
    result
  end
  

  def self.get_next_step(pending_txn)
    
    plsql_result = plsql.pk_qg_sc_step_engine.get_next_step(
      pi_auditable_type: pending_txn[:auditable_type],
      pi_step_no: pending_txn[:current_step_no],
      pi_step_status: pending_txn[:current_step_status],
      pi_step_action: pending_txn[:current_step_action],
      pi_step_attempt_cnt: pending_txn[:attempt_cnt],
      pi_switch_to_branch: pending_txn[:switch_to_branch_no],
      po_next_step_no: nil,
      po_next_step_action: nil,
      po_next_step_name: nil,
      po_txn_status: nil,
      po_next_step_action_at: nil,
      po_fault_code: nil,
      po_fault_subcode: nil,
      po_fault_reason: nil)
      
      result = {}
      result[:auditable_type] = pending_txn[:auditable_type]
      result[:auditable_id] = pending_txn[:auditable_id]
      
      result[:next_step_no] = plsql_result[:po_next_step_no]
      result[:next_step_action] = plsql_result[:po_next_step_action]
      result[:next_step_name] = plsql_result[:po_next_step_name]
      result[:txn_status] = plsql_result[:po_txn_status]
      result[:next_step_action_at] = plsql_result[:po_next_step_action_at]

      result[:fault_code] = plsql_result[:po_fault_code]
      result[:fault_subcode] = plsql_result[:po_fault_subcode]
      result[:fault_reason] = plsql_result[:po_fault_reason]

      result      
  end
  
  
  def self.set_action(next_step)    
        
    plsql_result = plsql.pk_qg_sc_step_helper.set_action(
      pi_auditable_type: next_step[:auditable_type],
      pi_auditable_id: next_step[:auditable_id],
      pi_txn_status: next_step[:txn_status],
      pi_step_no: next_step[:next_step_no],
      pi_step_action: next_step[:next_step_action],
      po_fault_code: nil,
      po_fault_subcode: nil,
      po_fault_reason: nil)
      
      result = {}
      result[:fault_code] = plsql_result[:po_fault_code]
      result[:fault_subcode] = plsql_result[:po_fault_subcode]
      result[:fault_reason] = plsql_result[:po_fault_reason]

      result
  end

  def self.set_step_result(step, step_result, switch_to_branch = nil)
    plsql.pk_qg_sc_step_helper.set_step_result(
      pi_auditable_type: step[:auditable_type],
      pi_auditable_id: step[:auditable_id],
      pi_step_result: step_result,
      pi_switch_to_branch: switch_to_branch
    )
  end

end

describe StepHelper do
  let(:auditable_type) { 'A' }
  let (:step) { {auditable_type: auditable_type, branch_no: 1, step_no: 1, step_name: 'A', max_retries: 0, do_is_idempotent: 'N', do_has_requery: 'N', do_must_complete: 'N', do_is_optional: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'} }
  
  before (:each) do
    StepHelper.setup([step])
  end
  
  context 'initialize' do    

    context 'for a new txn' do
      it 'should succeed' do
        expect(StepHelper.initialize(auditable_type, 1)).to be_initialized
      end
      
      context 'with start_in_debug' do
        it 'should succeed' do
          expect(StepHelper.initialize(auditable_type, 2, 'Y')).to be_initialized
        end
      end
    end

    context 'for a duplicate txn' do
      it 'should fail' do
        StepHelper.initialize(auditable_type, 1)
        expect(StepHelper.initialize(auditable_type, 1)).to not_complete.with_not_acceptible
      end
    end
  end
  
  context 'get_pending_txns' do
    context 'for a new txn' do
      it 'should get action do' do
        expect(StepHelper.initialize(auditable_type, 2)).to be_initialized
        expect(StepHelper.get_pending_txns(auditable_type)).to be_do
      end
    end
  end
end

describe StepHelper do  
  auditable_type = 'B'
  auditable_id = 1
  step = {auditable_type: auditable_type, branch_no: 1, step_name: 'A', max_retries: 0, do_is_idempotent: 'N', do_has_requery: 'N', do_must_complete: 'N', do_is_optional: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'}
  steps = Array.new(10, step)
  
  StepHelper.setup(steps)
  StepHelper.initialize(auditable_type, auditable_id)
  
  while (true) do
    pending_txn = StepHelper.get_pending_txns(auditable_type)
    exit if pending_txn.nil?
  
    if pending_txn[:txn_status] == 'NEW'
      step = {}
      step[:auditable_type] = pending_txn[:auditable_type]
      step[:auditable_id] = pending_txn[:auditable_id]
      step[:next_step_no] = pending_txn[:current_step_no]
      step[:next_step_action] = pending_txn[:current_step_action]
      step[:txn_status] = 'IN_PROGRESS'
    else
      step = StepHelper.get_next_step(pending_txn)      
    end
        
    break unless ['IN_PROGRESS','NEW'].include?step[:txn_status]    
    
    p "next step #{step[:next_step_no]}"

    StepHelper.set_action(step)
    if step[:next_step_no] == 8 
      StepHelper.set_step_result(step, 'N')  
    else
      StepHelper.set_step_result(step, 'Y')
    end
    
    sleep(1)
  end
  
  p step[:txn_status]
end