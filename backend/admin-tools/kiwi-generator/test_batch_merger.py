from batch_merger import ContentMerger, to_sql


def test_merge_replaces_old_quizzes_and_inserts_before_completion():
    base = {"steps": [
        {"step_type": "intro", "content": {}},
        {"stepType": "agglutinative_quiz", "contentObj": {"sentence": "old"}},
        {"step_type": "practice", "content": {}},
        {"step_type": "completion", "content": {}},
    ]}
    new = [{"stepType": "agglutinative_quiz", "contentObj": {"sentence": "new 1"}},
           {"stepType": "agglutinative_quiz", "contentObj": {"sentence": "new 2"}}]

    steps = ContentMerger.merge_content(base, new)["steps"]

    assert [s.get("stepType") or s.get("step_type") for s in steps] == \
        ["intro", "practice", "agglutinative_quiz", "agglutinative_quiz", "completion"]
    assert steps[2]["contentObj"]["sentence"] == "new 1"
    # 두 번 병합해도 같은 결과 (재실행 안전)
    assert ContentMerger.merge_content({"steps": steps}, new)["steps"] == steps


def test_quiz_steps_from_csv(tmp_path):
    csv = tmp_path / "c.csv"
    csv.write_text("UnitID,LessonID,Sentence,Translation,Target_POS\n"
                   "1,x,저는 학생이에요.,I am a student.,VCP\n1,y,저는 의사예요.,I am a doctor.,VCP\n",
                   encoding="utf-8")
    steps = ContentMerger().build_quiz_steps(str(csv), "x")
    assert len(steps) == 1
    s = steps[0]
    assert s["title"] == "Sentence Building #1" and "I am a student." in s["instruction"]
    assert "stepType" not in s["contentObj"]
    assert all("id" in o for o in s["contentObj"]["options"])
    assert all("text" not in e for e in s["contentObj"]["elements"])  # None 필드 제거


def test_to_sql_is_plain_update():
    sql = to_sql("u1-l1", {"steps": []})
    assert sql.startswith("UPDATE lessons SET content = $lsn$") and "WHERE lesson_id = 'u1-l1'" in sql
