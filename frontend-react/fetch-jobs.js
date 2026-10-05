const https = require('https');

https.get('https://api.github.com/repos/IT24100316/Campus-Placement-System/actions/runs?per_page=1', {
  headers: {
    'User-Agent': 'Node.js'
  }
}, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    const runs = JSON.parse(data).workflow_runs;
    const runId = runs[0].id;
    
    https.get(`https://api.github.com/repos/IT24100316/Campus-Placement-System/actions/runs/${runId}/jobs`, {
      headers: {
        'User-Agent': 'Node.js'
      }
    }, (res2) => {
      let data2 = '';
      res2.on('data', (chunk) => { data2 += chunk; });
      res2.on('end', () => {
        const jobs = JSON.parse(data2).jobs;
        console.log(JSON.stringify(jobs.map(j => ({
            name: j.name,
            status: j.status,
            conclusion: j.conclusion,
            steps: j.steps.map(s => ({ name: s.name, conclusion: s.conclusion }))
        })), null, 2));
      });
    });
  });
}).on('error', (e) => {
  console.error(e);
});
