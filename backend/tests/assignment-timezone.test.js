import assert from 'node:assert/strict';
import { test } from 'node:test';
import pool from '../db.js';
import { addAssignment, updateAssignment } from '../controllers/assignmentController.js';

for (const timezone of ['UTC', 'Africa/Johannesburg']) {
  for (const [name, handler, openIndex] of [
    ['create', addAssignment, 4],
    ['edit', updateAssignment, 2],
  ]) {
    for (const suffix of ['', '+02:00']) {
      test(`${name} keeps 08:45 South African time under ${timezone}, offset ${suffix || 'absent'}`, async (t) => {
        const previousTimezone = process.env.TZ;
        const execute = pool.execute;
        t.after(() => {
          pool.execute = execute;
          if (previousTimezone === undefined) delete process.env.TZ;
          else process.env.TZ = previousTimezone;
        });
        process.env.TZ = timezone;
        let stored;
        pool.execute = async (_sql, values) => {
          stored = values;
          return [{ affectedRows: 1 }];
        };
        let status = 200;
        const response = {
          status(value) { status = value; return this; },
          json(value) { return value; },
        };
        await handler({
          params: { moduleID: 2, assignmentID: 2 },
          user: { userID: 1 },
          body: {
            assignName: 'Test', assignDesc: 'Opening time regression',
            assignOpenDate: `2026-10-19T08:45:00${suffix}`,
            assignDueDate: `2026-10-19T09:45:00${suffix}`,
            assignTotalMarks: 10,
          },
        }, response);
        assert.equal(status, name === 'create' ? 201 : 200);
        assert.equal(stored[openIndex], '2026-10-19 08:45:00');
        assert.equal(stored[openIndex + 1], '2026-10-19 09:45:00');
      });
    }
  }
}
