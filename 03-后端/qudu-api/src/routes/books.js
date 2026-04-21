const express = require('express');
const router = express.Router();
const bookController = require('../controllers/bookController');
const { optionalAuth } = require('../middlewares/auth');

// 公开接口（不需要登录）
router.get('/themes', bookController.getThemes);
router.get('/free', bookController.getFreeBooks);
router.get('/recommended', optionalAuth, bookController.getRecommendedBooks);
router.get('/', bookController.getBooks);
router.get('/:id', optionalAuth, bookController.getBookDetail);

module.exports = router;
