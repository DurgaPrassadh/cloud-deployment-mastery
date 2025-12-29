const express = require('express');
const { body, param, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const router = express.Router();

// Validation middleware
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  next();
};

// Deployment validation rules
const deploymentValidation = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ max: 200 }).withMessage('Name must be less than 200 characters')
    .escape(),
  body('environment')
    .isIn(['development', 'staging', 'production']).withMessage('Invalid environment'),
  body('version')
    .trim()
    .notEmpty().withMessage('Version is required')
    .isLength({ max: 50 }).withMessage('Version must be less than 50 characters')
    .escape(),
  body('commit_sha')
    .trim()
    .notEmpty().withMessage('Commit SHA is required')
    .isLength({ min: 7, max: 40 }).withMessage('Invalid commit SHA')
    .escape(),
  body('branch')
    .trim()
    .notEmpty().withMessage('Branch is required')
    .isLength({ max: 100 }).withMessage('Branch must be less than 100 characters')
    .escape(),
];

// GET all deployments
router.get('/', async (req, res) => {
  try {
    const deployments = await db.getAll(
      'SELECT * FROM deployments ORDER BY started_at DESC LIMIT 50'
    );
    res.json({ success: true, data: deployments });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET single deployment
router.get('/:id',
  param('id').isUUID().withMessage('Invalid deployment ID'),
  validate,
  async (req, res) => {
    try {
      const deployment = await db.getOne(
        'SELECT * FROM deployments WHERE id = $1',
        [req.params.id]
      );
      if (!deployment) {
        return res.status(404).json({ success: false, error: 'Deployment not found' });
      }
      res.json({ success: true, data: deployment });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

// POST create deployment
router.post('/', deploymentValidation, validate, async (req, res) => {
  try {
    const { name, environment, version, commit_sha, branch } = req.body;
    const id = uuidv4();
    const now = new Date().toISOString();

    const deployment = await db.getOne(
      `INSERT INTO deployments (id, name, environment, status, version, commit_sha, branch, started_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [id, name, environment, 'building', version, commit_sha, branch, now]
    );

    // Simulate deployment process (in real scenario, trigger CI/CD pipeline)
    simulateDeployment(id);

    res.status(201).json({ success: true, data: deployment });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// DELETE (cancel) deployment
router.delete('/:id',
  param('id').isUUID().withMessage('Invalid deployment ID'),
  validate,
  async (req, res) => {
    try {
      const deployment = await db.getOne(
        `UPDATE deployments 
         SET status = 'failed', 
             completed_at = $1,
             duration_seconds = EXTRACT(EPOCH FROM ($1::timestamp - started_at))::integer
         WHERE id = $2 AND status IN ('pending', 'building', 'deploying')
         RETURNING *`,
        [new Date().toISOString(), req.params.id]
      );

      if (!deployment) {
        return res.status(404).json({ 
          success: false, 
          error: 'Deployment not found or cannot be cancelled' 
        });
      }

      res.json({ success: true, data: deployment, message: 'Deployment cancelled' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

// Simulate deployment process (replace with actual CI/CD integration)
async function simulateDeployment(id) {
  try {
    // Simulate building phase (10 seconds)
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    await db.query(
      "UPDATE deployments SET status = 'deploying' WHERE id = $1",
      [id]
    );

    // Simulate deploying phase (15 seconds)
    await new Promise(resolve => setTimeout(resolve, 15000));

    const now = new Date().toISOString();
    await db.query(
      `UPDATE deployments 
       SET status = 'success', 
           completed_at = $1,
           duration_seconds = EXTRACT(EPOCH FROM ($1::timestamp - started_at))::integer
       WHERE id = $2`,
      [now, id]
    );
  } catch (error) {
    console.error('Deployment simulation error:', error);
    await db.query(
      "UPDATE deployments SET status = 'failed', completed_at = $1 WHERE id = $2",
      [new Date().toISOString(), id]
    );
  }
}

module.exports = router;