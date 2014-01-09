class Sense < ActiveRecord::Base

  include Exportable

  belongs_to :lexeme
  belongs_to :synset

  has_many :relations, :foreign_key => "parent_id",
    :class_name => "SenseRelation"

  has_many :reverse_relations, :foreign_key => "child_id",
    :class_name => "SenseRelation"

  def as_json(options = {})
    data =  {
      :id => id,
      :lemma => lemma,
      :sense_index => sense_index,
      :language => language,
      :domain_id => domain_id,
      :comment => comment
    }

    if options[:synonyms]
      data[:synonyms] = synset.senses.map(&:as_json)
    end

    if options[:relations]
      data[:relations] =
        (relations.map { |r| r.as_json } +
        synset.relations.map { |r| r.as_json }).
        group_by { |r| r[:relation_id] }

      data[:reverse_relations] =
        (reverse_relations.map { |r| r.as_json(:reverse => true) } +
        synset.reverse_relations.map { |r| r.as_json(:reverse => true) }).
        group_by { |r| r[:relation_id] }
    end

    data
  end

  def self.export_index(connection)
    connection.create_schema_index(self.name, "id")
  end

  def self.export_query
    "MERGE (n:#{self.name} { id: {id} }) " +
    "ON CREATE SET " +
    "n.domain_id = {domain_id}, " +
    "n.comment = {comment}, " +
    "n.sense_index = {sense_index}, " +
    "n.language = {language}, " +
    "n.lemma = {lemma} " +
    "ON MATCH SET " +
    "n.domain_id = {domain_id}, " +
    "n.comment = {comment}, " +
    "n.sense_index = {sense_index}, " +
    "n.language = {language}, " +
    "n.lemma = {lemma}"
  end

  def self.export_properties(entity)
    entity.as_json.except(:external_id)
  end

end
