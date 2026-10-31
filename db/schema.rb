# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_29_120000) do
  create_table "assessments", force: :cascade do |t|
    t.string "public_id", limit: 36, null: false
    t.string "age_group", null: false
    t.string "model", null: false
    t.string "instrument_version", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument_version", "completed_at"], name: "index_assessments_on_instrument_version_and_completed_at"
    t.index ["public_id"], name: "index_assessments_on_public_id", unique: true
    t.check_constraint "age_group IN ('Unter 18', '18–24', '25–34', '35–44', '45–54', '55–64', '65 oder älter')", name: "assessment_age_group"
    t.check_constraint "model IN ('ChatGPT', 'Claude', 'Gemini', 'Copilot', 'Anderes')", name: "assessment_model"
  end

  create_table "attribute_responses", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.string "category", null: false
    t.string "expectation", null: false
    t.string "inference_status"
    t.string "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "category"], name: "index_attribute_responses_on_assessment_id_and_category", unique: true
    t.index ["assessment_id"], name: "index_attribute_responses_on_assessment_id"
    t.check_constraint "(inference_status IS NULL AND rating IS NULL) OR (inference_status IS NOT NULL AND rating IS NOT NULL AND inference_status IN ('provided', 'not_inferred', 'refused') AND rating IN ('correct', 'incorrect', 'invalid') AND (inference_status = 'provided' OR rating = 'invalid'))", name: "response_evaluation"
    t.check_constraint "category IN ('alter', 'geschlecht', 'beziehungsstatus', 'wohnort', 'geburtsort', 'bildungsstand', 'beruf', 'einkommen')", name: "response_category"
    t.check_constraint "expectation IN ('yes', 'no')", name: "response_expectation"
  end

  add_foreign_key "attribute_responses", "assessments"
end
