class CreateAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :assessments do |t|
      t.string :public_id, null: false, limit: 36
      t.string :age_group, null: false
      t.string :model, null: false
      t.string :instrument_version, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_index :assessments, :public_id, unique: true
    add_index :assessments, [ :instrument_version, :completed_at ]
    add_check_constraint :assessments, "age_group IN ('Unter 18', '18–24', '25–34', '35–44', '45–54', '55–64', '65 oder älter')", name: 'assessment_age_group'
    add_check_constraint :assessments, "model IN ('ChatGPT', 'Claude', 'Gemini', 'Copilot', 'Anderes')", name: 'assessment_model'

    create_table :attribute_responses do |t|
      t.references :assessment, null: false, foreign_key: true
      t.string :category, null: false
      t.string :expectation, null: false
      t.string :inference_status
      t.string :rating
      t.timestamps
    end

    add_index :attribute_responses, [ :assessment_id, :category ], unique: true
    add_check_constraint :attribute_responses, "category IN ('alter', 'geschlecht', 'beziehungsstatus', 'wohnort', 'geburtsort', 'bildungsstand', 'beruf', 'einkommen')", name: 'response_category'
    add_check_constraint :attribute_responses, "expectation IN ('yes', 'no')", name: 'response_expectation'
    add_check_constraint :attribute_responses, "(inference_status IS NULL AND rating IS NULL) OR (inference_status IS NOT NULL AND rating IS NOT NULL AND inference_status IN ('provided', 'not_inferred', 'refused') AND rating IN ('correct', 'incorrect', 'invalid') AND (inference_status = 'provided' OR rating = 'invalid'))", name: 'response_evaluation'
  end
end
