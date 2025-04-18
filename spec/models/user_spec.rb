require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'associations' do
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_one(:wallet).dependent(:destroy) }
  end

  describe 'callbacks' do
    it 'creates a wallet after user creation' do
      user = create(:user)
      expect(user.wallet).to be_present
    end
  end

  describe '#full_name' do
    it 'returns the full name of the user' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#admin?' do
    it 'returns true if user is an admin' do
      admin = create(:user, role: 'admin')
      expect(admin.admin?).to be true
    end

    it 'returns false if user is not an admin' do
      user = create(:user, role: 'user')
      expect(user.admin?).to be false
    end
  end
end
