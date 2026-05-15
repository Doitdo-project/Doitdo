import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
const accessToken = __ENV.ACCESS_TOKEN;
const path = __ENV.AUTH_CACHE_PATH || '/api/users/me/password';
const expectedStatus = Number(__ENV.EXPECTED_STATUS || 403);

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 399 }, expectedStatus));

export const options = {
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 200 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_reqs: ['count>0'],
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  if (!accessToken) {
    throw new Error('ACCESS_TOKEN is required');
  }

  const res = http.get(`${baseUrl}${path}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  check(res, {
    [`status is ${expectedStatus}`]: (r) => r.status === expectedStatus,
  });

  sleep(1);
}
