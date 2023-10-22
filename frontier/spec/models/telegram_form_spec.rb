# frozen_string_literal: true

# == Schema Information
#
# Table name: telegram_forms
#
#  id              :uuid             not null, primary key
#  author_group    :string
#  author_name     :string
#  chat_identifier :string
#  stage           :string           default(NULL), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  assignment_id   :uuid
#  course_id       :uuid
#  submission_id   :uuid
#
# Indexes
#
#  index_telegram_forms_on_assignment_id    (assignment_id)
#  index_telegram_forms_on_chat_identifier  (chat_identifier)
#  index_telegram_forms_on_course_id        (course_id)
#  index_telegram_forms_on_submission_id    (submission_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignment_id => assignments.id)
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (submission_id => submissions.id)
#
RSpec.describe TelegramForm do
  describe "constants" do
    describe "STAGES" do
      it { expect(described_class::STAGES).to be_an_instance_of(Array) }
      it { expect(described_class::STAGES).to all(be_an_instance_of(String)) }
      it { expect(described_class::STAGES).to be_frozen }
    end
  end

  describe "enumerations" do
    subject(:telegram_form) { described_class.new }

    specify do
      expect(telegram_form).to enumerize(:stage)
        .in(described_class::STAGES)
        .with_default("created")
        .with_scope(:shallow)
        .with_predicates(true)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:course).optional }
    it { is_expected.to belong_to(:assignment).optional }
    it { is_expected.to belong_to(:submission).optional }
  end

  describe "validatations" do
    it { is_expected.to validate_presence_of(:stage) }

    it { expect(build(:telegram_form, :course_provided)).to validate_presence_of(:course) }
    it { expect(build(:telegram_form, :assignment_provided)).to validate_presence_of(:assignment) }
    it { expect(build(:telegram_form, :author_name_provided)).to validate_presence_of(:author_name) }
    it { expect(build(:telegram_form, :author_group_provided)).to validate_presence_of(:author_group) }
    it { expect(build(:telegram_form, :uploads_provided)).to validate_presence_of(:submission) }
  end
end