# == Schema Information
#
# Table name: scites
#
#  id         :integer         primary key
#  sciter_id  :integer
#  paper_id   :integer
#  created_at :timestamp       not null
#  updated_at :timestamp       not null
#

class Scite < ActiveRecord::Base
  attr_accessible :paper_id

  belongs_to :sciter, class_name: "User", counter_cache: true
  belongs_to :paper, counter_cache: true 

  validates :sciter, presence: true
  validates :paper,  presence: true
end
