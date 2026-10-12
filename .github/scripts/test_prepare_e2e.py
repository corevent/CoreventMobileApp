import json
from contextlib import redirect_stderr
from io import StringIO
import subprocess
import unittest
from unittest.mock import patch
from uuid import uuid4

from prepare_e2e import extract_preparation, gcloud_json


class PreparationParserTest(unittest.TestCase):
    def test_failed_gcloud_reports_cause_without_printing_json_output(self):
        error = subprocess.CalledProcessError(
            1, ["gcloud"], output='{"private": "not-for-logs"}',
            stderr="ERROR: Permission denied\nrun.jobs.run is required",
        )
        logs = StringIO()
        with patch('prepare_e2e.subprocess.run', side_effect=error), redirect_stderr(logs):
            with self.assertRaises(subprocess.CalledProcessError):
                gcloud_json('run', 'jobs', 'execute', 'preparation')
        self.assertIn('gcloud: ERROR: Permission denied', logs.getvalue())
        self.assertIn('gcloud: run.jobs.run is required', logs.getvalue())
        self.assertNotIn('not-for-logs', logs.getvalue())

    def setUp(self):
        self.data = {
            key: str(uuid4()) for key in (
                "runId", "eventId", "userId", "freeTicketTypeId",
                "paidTicketTypeId", "orderId", "ticketId",
            )
        }
        self.data.update(schemaVersion=1, email="e2e@example.com", freeTicketName="Ingresso gratuito E2E")

    def parse(self, entries):
        return extract_preparation(entries, "e2e@example.com")

    def test_structured_and_text_logs(self):
        for entry in ({"jsonPayload": self.data}, {"textPayload": json.dumps(self.data)}):
            self.assertEqual(self.parse([entry]), self.data)

    def test_ignores_other_logs_and_waits_for_missing_result(self):
        self.assertIsNone(self.parse([{"textPayload": "Starting"}, {"jsonPayload": {"message": "done"}}]))

    def test_deduplicates_same_result(self):
        self.assertEqual(self.parse([{"jsonPayload": self.data}] * 2), self.data)

    def test_rejects_ambiguous_results(self):
        other = {**self.data, "runId": str(uuid4())}
        with self.assertRaises(ValueError):
            self.parse([{"jsonPayload": self.data}, {"jsonPayload": other}])

    def test_rejects_invalid_schema_account_id_and_multiline_name(self):
        for changes in (
            {"schemaVersion": 2}, {"email": "other@example.com"},
            {"eventId": "invalid"}, {"eventId": None},
            {"freeTicketName": "name\nevent_id=wrong"},
            {"freeTicketName": ""},
        ):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.parse([{"jsonPayload": {**self.data, **changes}}])


if __name__ == "__main__":
    unittest.main()
