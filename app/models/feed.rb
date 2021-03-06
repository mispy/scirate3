# == Schema Information
#
# Table name: feeds
#
#  id                  :integer         not null, primary key
#  name                :string(255)
#  url                 :string(255)
#  feed_type           :string(255)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  updated_date        :date
#  subscriptions_count :integer         default(0)
#  last_paper_date     :date
#

class Feed < ActiveRecord::Base
  attr_accessible :name, :url, :feed_type, :updated_date, :last_paper_date

  has_many :papers, validate: false
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions
  has_many :cross_lists, dependent: :destroy
  has_many :cross_listed_papers, through: :cross_lists, source: :paper

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true
  validates :feed_type, presence: true
  validates :updated_date, presence: true

  def self.arxiv_import(feednames, opts={})
    existing = Feed.all.map(&:name)

    columns = [:name, :url, :feed_type]
    values = []
    
    (feednames - existing).map do |feedname|
      puts "Discovered new feed: #{feedname}"
      values << [
        feedname,
        "http://export.arxiv.org/rss/#{feedname}",
        "arxiv"
      ]
    end

    result = Feed.import(columns, values, opts)
    unless result.failed_instances.empty?
      Scirate3.notify_error("Error importing feeds: #{result.failed_instances.inspect}")
    end
  end

  def self.get_or_create(name)
    feed = Feed.find_by_name(name)
    return feed unless feed.nil?
    feed = Feed.new
    feed.name = name
    feed.url = "http://export.arxiv.org/rss/#{name}"
    feed.feed_type = 'arxiv'
    feed.updated_date = Time.now.utc.to_date - 1.day
    feed.save!
    feed
  end

  def self.map_names
    mapping = {}
    Feed.all.each { |feed| mapping[feed.name] = feed }
    mapping
  end

  def to_param
    name
  end

  def self.default
    Feed.find_by_name("quant-ph") || Feed.create_default
  end

  def is_default?
    self == Feed.default
  end

  def self.create_default
    Feed.create(name: "quant-ph",
                url: "http://export.arxiv.org/rss/quant-ph",
                feed_type: "arxiv",
                updated_date: Time.now.utc.to_date,
                last_paper_date: Time.now.utc.to_date)
  end

  def update_last_paper_date
    paper = self.papers.order("pubdate asc").last
    unless paper.nil?
      self.last_paper_date = paper.pubdate
      self.updated_date = paper.updated_date
      self.save!
    end
  end
end
