require 'rspec/expectations'

module GetStepMatchers
  RSpec::Matchers.define :be_completed do
    match do |response|
      expect(response[:txn_status]).to eq('COMPLETED')
      expect(response[:next_step_no]).to be_nil
      expect(response[:next_step_action]).to be_nil
      expect(response[:next_step_name]).to be_nil
      expect(response[:next_step_branch_no]).to be_nil
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected txn_status to be COMPLETED instead of #{response}"
    end
  end
  
  RSpec::Matchers.define :be_failed do
    match do |response|
      expect(response[:txn_status]).to eq('FAILED')
      expect(response[:next_step_no]).to be_nil
      expect(response[:next_step_action]).to be_nil
      expect(response[:next_step_name]).to be_nil
      expect(response[:next_step_branch_no]).to be_nil
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected txn_status to be FAILED instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_reversed do
    match do |response|
      expect(response[:txn_status]).to eq('REVERSED')
      expect(response[:next_step_no]).to be_nil
      expect(response[:next_step_action]).to be_nil
      expect(response[:next_step_name]).to be_nil
      expect(response[:next_step_branch_no]).to be_nil
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected txn_status to be FAILED instead of #{response}"
    end
  end    
  
  RSpec::Matchers.define :be_onhold do
    match do |response|
      expect(response[:txn_status]).to eq('ONHOLD')
      expect(response[:next_step_no]).to be_nil
      expect(response[:next_step_action]).to be_nil
      expect(response[:next_step_name]).to be_nil
      expect(response[:next_step_branch_no]).to be_nil
      expect(response[:fault_code]).to eq(@fault_code)
      expect(response[:fault_reason]).to_not be_nil
    end

    chain :with_too_many_attempts do
      @fault_code = 'ns:E508'
    end
    
    chain :with_conflict do
      @fault_code = 'ns:E409'
    end
    
    chain :with_no_option do
      @fault_code = 'ns:E412'
    end
    
    chain :with_pending_action do
     @fault_code = 'ns:E202'
    end
    
    failure_message do |response|
        "expected txn_status to be ONHOLD instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_next_step do |step|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(step[:step_no] + 1)
      expect(response[:next_step_action]).to eq('DO')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected next_step_action to be DO of step #{step} instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_prev_step do |step, prev_step_no|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(prev_step_no.nil? ? step[:step_no] - 1 : prev_step_no)
      expect(response[:next_step_action]).to eq('REVERSE')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected to be action REVERSE for previous step at #{prev_step_no} of step #{step} instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_step_no do |step_no|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(step_no)
      expect(response[:next_step_action]).to eq('DO')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected to be first step #{step_no} of branch #{branch_no} instead of #{response}"
    end
  end    
    
  
  RSpec::Matchers.define :be_requery do |step|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(step[:step_no])
      expect(response[:next_step_action]).to eq('REQUERY')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected next_step_action to be REQUERY of step #{step} instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :retry_do do |step|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(step[:step_no])
      expect(response[:next_step_action]).to eq('DO')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected next_step_action to be REQUERY of step #{step} instead of #{response}"
    end
  end  

  RSpec::Matchers.define :retry_reverse do |step|
    match do |response|
      expect(response[:txn_status]).to eq('IN_PROGRESS')
      expect(response[:next_step_no]).to eq(step[:step_no])
      expect(response[:next_step_action]).to eq('REVERSE')
      expect(response[:fault_code]).to be_nil
      expect(response[:fault_subcode]).to be_nil
      expect(response[:fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected next_step_action to be REQUERY of step #{step} instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_correct do
    match do |response|
      expect(response[:po_fault_code]).to be_nil
      expect(response[:po_fault_subcode]).to be_nil
      expect(response[:po_fault_reason]).to be_nil
    end
    
    failure_message do |response|
        "expected result to be correct instead of #{response}"
    end
  end  
  
  RSpec::Matchers.define :be_incorrect do
    match do |response|
      expect(response[:po_fault_code]).to eq(@fault_code.nil? ? 'ns:E400' : @fault_code)
      expect(response[:po_fault_reason]).to_not be_nil
    end
    
    chain :with_not_acceptible do
      @fault_code = 'ns:E406'
    end
    
    
    failure_message do |response|
        "expected result to be incorrect instead of #{response}"
    end
  end  
  
end