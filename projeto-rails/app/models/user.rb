
class User < ApplicationRecord
  has_one :account, dependent: :destroy

  def staff?
    student_id.to_s.start_with?("999")
  end

  def student?
    !staff?
  end

  def admin?
    staff?
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb