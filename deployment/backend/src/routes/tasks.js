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

// Task validation rules
const taskValidation = [
  body('title')
    .trim()
    .notEmpty().withMessage('Title is required')
    .isLength({ max: 200 }).withMessage('Title must be less than 200 characters')
    .escape(),
  body('description')
    .trim()
    .isLength({ max: 2000 }).withMessage('Description must be less than 2000 characters')
    .escape(),
  body('priority')
    .isIn(['low', 'medium', 'high', 'critical']).withMessage('Invalid priority'),
  body('environment')
    .isIn(['development', 'staging', 'production']).withMessage('Invalid environment'),
  body('assignee')
    .optional()
    .trim()
    .isLength({ max: 100 }).withMessage('Assignee must be less than 100 characters')
    .escape(),
];

// GET all tasks
router.get('/', async (req, res) => {
  try {
    const tasks = await db.getAll(
      'SELECT * FROM tasks ORDER BY created_at DESC'
    );
    res.json({ success: true, data: tasks });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET single task
router.get('/:id', 
  param('id').isUUID().withMessage('Invalid task ID'),
  validate,
  async (req, res) => {
    try {
      const task = await db.getOne(
        'SELECT * FROM tasks WHERE id = $1',
        [req.params.id]
      );
      if (!task) {
        return res.status(404).json({ success: false, error: 'Task not found' });
      }
      res.json({ success: true, data: task });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

// POST create task
router.post('/', taskValidation, validate, async (req, res) => {
  try {
    const { title, description, priority, environment, assignee } = req.body;
    const id = uuidv4();
    const now = new Date().toISOString();

    const task = await db.getOne(
      `INSERT INTO tasks (id, title, description, status, priority, environment, assignee, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [id, title, description || '', 'pending', priority, environment, assignee || null, now, now]
    );

    res.status(201).json({ success: true, data: task });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// PUT update task
router.put('/:id',
  param('id').isUUID().withMessage('Invalid task ID'),
  body('status')
    .optional()
    .isIn(['pending', 'in_progress', 'completed', 'failed']).withMessage('Invalid status'),
  validate,
  async (req, res) => {
    try {
      const { title, description, status, priority, environment, assignee } = req.body;
      const now = new Date().toISOString();

      const task = await db.getOne(
        `UPDATE tasks 
         SET title = COALESCE($1, title),
             description = COALESCE($2, description),
             status = COALESCE($3, status),
             priority = COALESCE($4, priority),
             environment = COALESCE($5, environment),
             assignee = COALESCE($6, assignee),
             updated_at = $7
         WHERE id = $8
         RETURNING *`,
        [title, description, status, priority, environment, assignee, now, req.params.id]
      );

      if (!task) {
        return res.status(404).json({ success: false, error: 'Task not found' });
      }

      res.json({ success: true, data: task });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

// DELETE task
router.delete('/:id',
  param('id').isUUID().withMessage('Invalid task ID'),
  validate,
  async (req, res) => {
    try {
      const result = await db.query(
        'DELETE FROM tasks WHERE id = $1 RETURNING id',
        [req.params.id]
      );

      if (result.rowCount === 0) {
        return res.status(404).json({ success: false, error: 'Task not found' });
      }

      res.json({ success: true, message: 'Task deleted' });
    } catch (error) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
);

module.exports = router;