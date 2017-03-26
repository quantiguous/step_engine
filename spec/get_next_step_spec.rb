require_relative 'matchers'

class Setup
  
  def initialize(auditable_type, steps_cnt = 1)
    x = {do_is_optional: 'N', do_must_complete: 'N', max_retries: 0, do_is_idempotent: 'N', do_has_requery: 'N', skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N'}

    plsql.sc_service_op_steps.delete auditable_type: auditable_type
    (1..steps_cnt).each do |i|
      plsql.sc_service_op_steps.insert x.merge({id: plsql.sc_service_op_steps_seq.nextval, auditable_type: auditable_type, branch_no: 1, step_no: i, step_name: "step #{i}"})
    end
    plsql.commit
    
    @auditable_type = auditable_type
  end

  def do_must_complete(step_no = 1)
    plsql.sc_service_op_steps.update do_is_optional: 'N', do_must_complete: 'Y', max_retries: 0, where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def do_is_optional(step_no = 1)
    plsql.sc_service_op_steps.update do_is_optional: 'Y', do_must_complete: 'N', max_retries: 0, where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def do_is_not_optional(step_no = 1)
    plsql.sc_service_op_steps.update do_is_optional: 'N', do_must_complete: 'N', max_retries: 0, where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def skip_reversal(from_step_no = 1, to_step_no = 1)
    (to_step_no..from_step_no-1).each do |s|
      plsql.sc_service_op_steps.update skip_reversal: 'Y', reversal_is_idempotent: 'N', reversal_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: s}
    end
  end

  def do_not_skip_reversal(from_step_no = 1, to_step_no = 1)
    (to_step_no..from_step_no-1).each do |s|
      plsql.sc_service_op_steps.update skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: s}
    end  
  end
    
  def reversal_has_requery(step_no = 1)
    plsql.sc_service_op_steps.update skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'Y', where: {auditable_type: @auditable_type, step_no: step_no}
  end

  def reversal_does_not_have_requery(step_no = 1)
    plsql.sc_service_op_steps.update skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end

  def reversal_is_idempotent(step_no = 1)
    plsql.sc_service_op_steps.update skip_reversal: 'N', reversal_is_idempotent: 'Y', reversal_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end

  def reversal_is_not_idempotent(step_no = 1)
    plsql.sc_service_op_steps.update skip_reversal: 'N', reversal_is_idempotent: 'N', reversal_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def do_has_requery(step_no = 1)
    plsql.sc_service_op_steps.update do_is_idempotent: 'N', do_has_requery: 'Y', where: {auditable_type: @auditable_type, step_no: step_no}
  end

  def do_does_not_have_requery(step_no = 1)
    plsql.sc_service_op_steps.update do_is_idempotent: 'N', do_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end
    
  def do_is_idempotent(step_no = 1)
    plsql.sc_service_op_steps.update do_is_idempotent: 'Y', do_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def do_is_not_idempotent(step_no = 1)
    plsql.sc_service_op_steps.update do_is_idempotent: 'N', do_has_requery: 'N', where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def max_retries_one(step_no = 1)
    plsql.sc_service_op_steps.update max_retries: 1, where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def max_retries_zero(step_no = 1)
    plsql.sc_service_op_steps.update max_retries: 0, where: {auditable_type: @auditable_type, step_no: step_no}
  end
  
  def pretty_print(step_no = 1)
    p plsql.select(:first, "select * from sc_service_op_steps where auditable_type = '#{@auditable_type}' and step_no = #{step_no}")
  end
end

describe 'Step' do
  include GetStepMatchers
    
  let (:step) { { step_no: 1, branch_no: 1, step_status: nil, step_action: nil, step_attempt_cnt: 1, switch_to_branch: nil} }
    
  def get_next_step
    plsql_result = plsql.pk_qg_sc_step_engine.get_next_step(
      pi_auditable_type: step[:auditable_type], 
      pi_step_no: step[:step_no], 
      pi_step_status: step[:step_status], 
      pi_step_action: step[:step_action], 
      pi_step_attempt_cnt: step[:step_attempt_cnt], 
      pi_switch_to_branch: step[:swtich_to_branch], 
      po_next_step_no: nil, 
      po_next_step_action: nil, 
      po_next_step_name: nil, 
      po_next_branch_no: nil, 
      po_txn_status: nil,
      po_fault_code: nil, 
      po_fault_subcode: nil, 
      po_fault_reason: nil)
      
    result = {}
    result[:next_step_no] = plsql_result[:po_next_step_no]
    result[:next_step_action] = plsql_result[:po_next_step_action]
    result[:next_step_name] = plsql_result[:po_next_step_name]
    result[:next_step_branch_no] = plsql_result[:po_next_branch_no]
    result[:txn_status] = plsql_result[:po_txn_status]
    result[:fault_code] = plsql_result[:po_fault_code]
    result[:fault_subcode] = plsql_result[:po_fault_subcode]
    result[:fault_reason] = plsql_result[:po_fault_reason]
    
    result
  end
  
  RSpec.shared_context 'any step' do
    # common for a step, that dont depend on the position of the step
    context "for every step" do
      let (:step) { super().merge({step_no: step_no}) }
      
      context 'with status TRIED' do
        let (:step) { super().merge({step_status: 'TRIED'}) }

        context 'and do_is_optional = N' do    
          it 'should get txn_status ONHOLD with conflict' do
            expect(get_next_step).to be_onhold.with_conflict
          end
        end      
      end
      
      
      context 'with status DOING' do
        let (:step) { super().merge({step_status: 'DOING'}) }

        context 'and action REVERSE' do
          let (:step) { super().merge({step_action: 'REVERSE'}) }

          it 'should get txn_status ONHOLD with conflict' do
            expect(get_next_step).to be_onhold.with_conflict
          end      
        end

        context 'and action REQUERY' do
          let (:step) { super().merge({step_action: 'REQUERY'}) }

          context 'and does not have requery' do
            it 'should get txn_status ONHOLD with conflict' do
              expect(get_next_step).to be_onhold.with_conflict
            end   
          end
  
          context ' and has_requery ' do
            before(:all) do
              @setup.do_has_requery(@step_no)
            end
            after(:all) do
              @setup.do_does_not_have_requery(@step_no)
            end
    
            context 'and max_retries = 0' do
              context 'and first attempt' do
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get txn_status ONHOLD with_too_many_attempts' do
                  expect(get_next_step).to be_onhold.with_too_many_attempts
                end
              end
            end

            context 'and max_retries = 1' do
              before(:all) do
                @setup.max_retries_one(@step_no)
              end
              after(:all) do
                @setup.max_retries_zero(@step_no)
              end
              
              context 'and first attempt' do
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get next_action REQUERY' do
                  expect(get_next_step).to be_requery(step)
                end
              end
            end
    
          end
        end

        context 'and action DO' do
          let (:step) { super().merge({step_action: 'DO'}) }
  
          context 'and do_is_not_idempotent and does not have requery' do
            it 'should get txn_status ONHOLD with_no_option' do
              expect(get_next_step).to be_onhold.with_no_option
            end
          end

          context 'and first attempt' do
            context 'and has_requery' do
              # max_retries does not matter for the first attempt, as we switch to requery
              before(:all) do
                @setup.do_has_requery(@step_no)
              end
              after(:all) do
                @setup.do_does_not_have_requery(@step_no)
              end            
                
              let (:step) { super().merge({step_attempt_cnt: 1}) }

              it 'should get next_action REQUERY' do
                expect(get_next_step).to be_requery(step)
              end
            end
            context 'and do_is_idempotent' do
              context 'and max_retries = 0' do
                before(:all) do
                  @setup.do_is_idempotent(@step_no)
                end
                after(:all) do
                  @setup.do_is_not_idempotent(@step_no)
                end               
                  
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get txn_status ONHOLD with_too_many_attempts' do
                  expect(get_next_step).to be_onhold.with_too_many_attempts
                end
              end            
              context 'and max_retries = 1' do
                before(:all) do
                  @setup.do_is_idempotent(@step_no)
                  @setup.max_retries_one(@step_no)
                end
                after(:all) do
                  @setup.do_is_not_idempotent(@step_no)
                  @setup.max_retries_zero(@step_no)
                end               
                  
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get next_action DO' do
                  expect(get_next_step).to retry_do(step)
                end
              end
            end
              
          end
        end        
      end     
    end
  end
  
  RSpec.shared_context 'first step' do
    # cases for the first step, irrespective of the no of steps in the branch
    context 'for first step' do
      context 'with status REVERSING' do
        let (:step) { super().merge({step_status: 'REVERSING'}) }
      
        it 'should get txn_status ONHOLD with conflict' do
          expect(get_next_step).to be_onhold.with_conflict
        end
      end
      
      context 'with status FAILED' do
        let (:step) { super().merge({step_status: 'FAILED'}) }
  
        it 'should get txn_status FAILED' do
          expect(get_next_step).to be_failed
        end
      end      
       
      context 'with status REVERSED' do
        let (:step) { super().merge({step_status: 'REVERSING'}) }

        it 'should get txn_status ONHOLD with conflict' do
          expect(get_next_step).to be_onhold.with_conflict
        end
      end
    end
  end
  
  RSpec.shared_context 'last step' do
    # cases for the last step, irrespective of the no of steps in the branch
    context 'for last step' do
      let (:step) { super().merge({step_no: last_step_no})}
      
      context 'with status DONE' do
        let (:step) { super().merge({step_status: 'DONE'}) }
  
        it 'should get txn_status COMPLETED' do
          expect(get_next_step).to be_completed
        end
      end

      context 'with status REVERSED' do
        let (:step) { super().merge({step_status: 'REVERSED'}) }
      
        it 'should get txn_status ONHOLD with conflict' do
          expect(get_next_step).to be_onhold.with_conflict
        end
      end

      context 'with status REVERSING' do
        let (:step) { super().merge({step_status: 'REVERSING'}) }
      
        it 'should get txn_status ONHOLD with conflict' do
          expect(get_next_step).to be_onhold.with_conflict
        end
      end
    end
  end
  
  RSpec.shared_context 'first and only step' do
    # cases when no_of_steps = 1 for a branch
    context 'for first and only step' do
      
      context 'with status TRIED' do
        context 'with do_is_optional' do
          before(:all) do
            @setup.do_is_optional
          end
          after(:all) do
            @setup.do_is_not_optional
          end

          let (:step) { super().merge({step_status: 'TRIED'}) }
  
          it 'should get txn_status FAILED' do
            expect(get_next_step).to be_failed
          end
        end
      end      
    end
  end

  # there are no specific cases for a step that is first of many
  # RSpec.shared_context 'last step of many' do
  # end
  
  RSpec.shared_context 'last step of many' do
    # cases for the last step, when no_of_steps > 1 for a branch
    context 'for last of many steps' do
      let (:step) { super().merge({step_no: last_step_no})}
      
      
      context 'with status TRIED' do
        context 'with do_is_optional' do
          before(:all) do
            @setup.do_is_optional(@last_step_no)
          end
          after(:all) do
            @setup.do_is_not_optional(@last_step_no)
          end

          let (:step) { super().merge({step_status: 'TRIED'}) }
  
          it 'should get txn_status COMPLETED' do            
            expect(get_next_step).to be_completed
          end
        end
      end
      
    end
  end
    
  RSpec.shared_context 'except first of many steps' do
    # cases for steps other than the first one, including the last
    context 'for step except first' do
      let (:step) { super().merge({step_no: step_no}) }

      context 'with status FAILED' do
        let (:step) { super().merge({step_status: 'FAILED'}) }
        
        context 'with skip_reversal = N for previous step' do        
          it 'should get prev_step_no with action REVERSE' do            
            expect(get_next_step).to be_prev_step(step)
          end
        end
        
        context 'with skip_reversal = Y for all remaining previous steps' do
          before(:all) do
            @setup.skip_reversal(@step_no)
            plsql.commit
          end
          after(:all) do
            @setup.do_not_skip_reversal(@step_no)
          end

          it 'should get txn_status FAILED' do            
            expect(get_next_step).to be_failed
          end
        end
      end
      
    end
  end
  
  RSpec.shared_context 'except last of many steps' do
    # cases for steps other than the last one, including the first
    context 'for step except last of many steps' do
      let (:step) { super().merge({step_no: step_no}) }

      context 'with status DONE' do
        let (:step) { super().merge({step_status: 'DONE'}) }
        
        it 'should get next_step_no with action DO' do            
          expect(get_next_step).to be_next_step(step)
        end
      end

      context 'with status TRIED' do
        before(:all) do
          @setup.do_is_optional(@step_no)
        end
        after(:all) do
          @setup.do_is_not_optional(@step_no)
        end
        let (:step) { super().merge({step_status: 'TRIED'}) }
        
        it 'should get next_step_no with action DO' do            
          expect(get_next_step).to be_next_step(step)
        end
      end
    end
  end
  
  RSpec.shared_context 'except first and last of many steps' do
    # case for steps other than the first and last one
    context 'for steps other than first and last' do
      let (:step) { super().merge({step_no: step_no}) }

      context 'with status REVERSED' do
        let (:step) { super().merge({step_status: 'REVERSED'}) }
        
        context 'with skip_reversal = N for previous step' do        
          it 'should get prev_step_no with action REVERSE' do            
            expect(get_next_step).to be_prev_step(step)
          end
        end
        
        context 'with skip_reversal = Y for all remaining previous steps' do
          before(:all) do
            @setup.skip_reversal(@step_no)
          end
          after(:all) do
            @setup.do_not_skip_reversal(@step_no)
          end

          it 'should get txn_status REVERSED' do            
            expect(get_next_step).to be_reversed
          end
        end
      end

      context 'with status REVERSING' do
        let (:step) { super().merge({step_status: 'REVERSING'}) }

        context 'and skip_reversal = Y' do
          before(:all) do
            @setup.skip_reversal(@step_no+1, @step_no)
          end
          after(:all) do
            @setup.do_not_skip_reversal(@step_no+1, @step_no)
          end          

          it 'should get txn_status ONHOLD with conflict' do
            expect(get_next_step).to be_onhold.with_conflict
          end      
        end
        
        
        context 'and action DO' do
          let (:step) { super().merge({step_action: 'DO'}) }

          it 'should get txn_status ONHOLD with conflict' do
            expect(get_next_step).to be_onhold.with_conflict
          end      
        end

        context 'and action REQUERY' do
          let (:step) { super().merge({step_action: 'REQUERY'}) }

          context 'and does not have requery' do
            it 'should get txn_status ONHOLD with conflict' do
              expect(get_next_step).to be_onhold.with_conflict
            end   
          end
  
          context ' and has_requery ' do
            before(:all) do
              @setup.reversal_has_requery(@step_no)
            end
            after(:all) do
              @setup.reversal_does_not_have_requery(@step_no)
            end
    
            context 'and max_retries = 0' do
              context 'and first attempt' do
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get txn_status ONHOLD with_too_many_attempts' do
                  expect(get_next_step).to be_onhold.with_too_many_attempts
                end
              end
            end

            context 'and max_retries = 1' do
              before(:all) do
                @setup.max_retries_one(@step_no)
              end
              after(:all) do
                @setup.max_retries_zero(@step_no)
              end
              
              context 'and first attempt' do
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get next_action REQUERY' do
                  expect(get_next_step).to be_requery(step)
                end
              end
            end
    
          end
        end

        context 'and action REVERSE' do
          let (:step) { super().merge({step_action: 'REVERSE'}) }
  
          context 'and reversal_is_not_idempotent and reversal does not have requery (do_has_requery)' do
            before(:all) do
              @setup.do_has_requery(@step_no)
            end
            after(:all) do
              @setup.do_does_not_have_requery(@step_no)
            end            
            
            it 'should get txn_status ONHOLD with_no_option' do
              expect(get_next_step).to be_onhold.with_no_option
            end
          end

          context 'and reversal_is_not_idempotent and reversal does not have requery (do_is_idempotnent)' do
            before(:all) do
              @setup.do_is_idempotent(@step_no)
            end
            after(:all) do
              @setup.do_is_not_idempotent(@step_no)
            end            
            
            it 'should get txn_status ONHOLD with_no_option' do
              expect(get_next_step).to be_onhold.with_no_option
            end
          end

          context 'and reversal_is_not_idempotent and does not have requery' do
            it 'should get txn_status ONHOLD with_no_option' do
              expect(get_next_step).to be_onhold.with_no_option
            end
          end

          context 'and first attempt' do
            context 'and reversal_has_requery' do
              # max_retries does not matter for the first attempt, as we switch to requery
              before(:all) do
                @setup.reversal_has_requery(@step_no)
              end
              after(:all) do
                @setup.reversal_does_not_have_requery(@step_no)
              end            
                
              let (:step) { super().merge({step_attempt_cnt: 1}) }

              it 'should get next_action REQUERY' do
                expect(get_next_step).to be_requery(step)
              end
            end
            context 'and reversal_is_idempotent' do
              context 'and max_retries = 0' do
                before(:all) do
                  @setup.reversal_is_idempotent(@step_no)
                end
                after(:all) do
                  @setup.reversal_is_not_idempotent(@step_no)
                end               
                  
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get txn_status ONHOLD with_too_many_attempts' do
                  expect(get_next_step).to be_onhold.with_too_many_attempts
                end
              end            
              context 'and max_retries = 1' do
                before(:all) do
                  @setup.reversal_is_idempotent(@step_no)
                  @setup.max_retries_one(@step_no)
                end
                after(:all) do
                  @setup.reversal_is_not_idempotent(@step_no)
                  @setup.max_retries_zero(@step_no)
                end               
                  
                let (:step) { super().merge({step_attempt_cnt: 1}) }

                it 'should get next_action REVERSE' do
                  expect(get_next_step).to retry_reverse(step)
                end
              end
            end
          end          
        end
      end
    end
  end
  
  
  context '(steps: 1)' do
    before(:all) do
      @setup = Setup.new('one step')
      @last_step_no = 1
      @step_no = 1
    end

    let (:last_step_no) { 1 }
    let (:step) { super().merge({auditable_type: 'one step'})}

    include_context 'first step'
    include_context 'first and only step'
    include_context 'last step'

    let (:step_no) { 1 }
    include_context 'any step'
  end


  context '(steps: = 2)' do
    before(:all) do
      @setup = Setup.new('two steps', 2)
      @last_step_no = 2
    end

    let (:last_step_no) { 2 }
    let (:step) { super().merge({auditable_type: 'two steps'})}

    include_context 'first step'
    include_context 'last step'
    include_context 'last step of many'

    context '' do
      before(:all) do
        @step_no = 1
      end
      let (:step_no) { 1 }
      include_context 'any step'
      include_context 'except last of many steps'
    end

    context '' do
      before(:all) do
        @step_no = 2
      end
      let (:step_no) { 2 }
      include_context 'any step'
      include_context 'except first of many steps'
    end

  end

  context '(steps: = 3)' do
    before(:all) do
      @setup = Setup.new('three steps', 3)
      @last_step_no = 3
    end

    let (:last_step_no) { 3 }
    let (:step) { super().merge({auditable_type: 'three steps'})}

    include_context 'first step'
    include_context 'last step'
    include_context 'last step of many'

    context '' do
      before(:all) do
        @step_no = 1
      end
      let (:step_no) { 1 }
      include_context 'any step'
      include_context 'except last of many steps'
    end

    context '' do
      before(:all) do
        @step_no = 2
      end
      let (:step_no) { 2 }
      include_context 'any step'
      include_context 'except last of many steps'
      include_context 'except first of many steps'
      include_context 'except first and last of many steps'
    end

    context '' do
      before(:all) do
        @step_no = 3
      end
      let (:step_no) { 3 }
      include_context 'any step'
      include_context 'except first of many steps'
    end
  end
  
end
