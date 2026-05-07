const axios = require('axios');
const config = require('../config');

/**
 * 微信登录 Service
 * 封装微信开放平台API调用
 */

// ========== Mock模式支持（MVP阶段） ==========
function isMockMode() {
  return config.wechat.appId === 'mock';
}

const MOCK_TOKEN_DATA = {
  access_token: 'mock_access_token_' + Date.now(),
  expires_in: 7200,
  refresh_token: 'mock_refresh_token_' + Date.now(),
  openid: 'mock_openid_' + Math.random().toString(36).substr(2, 9),
  scope: 'snsapi_userinfo',
  unionid: 'mock_unionid_' + Math.random().toString(36).substr(2, 9)
};

const MOCK_USER_INFO = {
  openid: MOCK_TOKEN_DATA.openid,
  nickname: '微信测试用户',
  sex: 0,
  province: '广东',
  city: '深圳',
  country: '中国',
  headimgurl: '',
  privilege: [],
  unionid: MOCK_TOKEN_DATA.unionid
};
// ================================================

const WECHAT_API = {
  ACCESS_TOKEN: 'https://api.weixin.qq.com/sns/oauth2/access_token',
  USER_INFO: 'https://api.weixin.qq.com/sns/userinfo',
  REFRESH_TOKEN: 'https://api.weixin.qq.com/sns/oauth2/refresh_token',
  VERIFY_TOKEN: 'https://api.weixin.qq.com/sns/auth'
};

/**
 * 用code换取access_token
 * @param {string} code - 微信授权码
 * @returns {Promise<Object>} { access_token, expires_in, refresh_token, openid, scope, unionid }
 */
async function getAccessToken(code) {
  // MVP Mock模式：不调用真实微信API
  if (isMockMode()) {
    console.log('[WechatService] Mock模式：模拟获取access_token，code:', code);
    return { ...MOCK_TOKEN_DATA, openid: MOCK_TOKEN_DATA.openid, access_token: MOCK_TOKEN_DATA.access_token };
  }

  try {
    const res = await axios.get(WECHAT_API.ACCESS_TOKEN, {
      params: {
        appid: config.wechat.appId,
        secret: config.wechat.appSecret,
        code,
        grant_type: 'authorization_code'
      }
    });

    if (res.data.errcode) {
      throw new Error(`微信授权失败[${res.data.errcode}]: ${res.data.errmsg}`);
    }

    return res.data;
  } catch (err) {
    console.error('[WechatService] 获取access_token失败:', err.message);
    throw err;
  }
}

/**
 * 获取用户信息
 * @param {string} accessToken - 访问令牌
 * @param {string} openid - 用户OpenID
 * @returns {Promise<Object>} { openid, nickname, sex, province, city, country, headimgurl, privilege, unionid }
 */
async function getUserInfo(accessToken, openid) {
  // MVP Mock模式
  if (isMockMode()) {
    console.log('[WechatService] Mock模式：模拟获取用户信息');
    return MOCK_USER_INFO;
  }

  try {
    const res = await axios.get(WECHAT_API.USER_INFO, {
      params: {
        access_token: accessToken,
        openid
      }
    });

    if (res.data.errcode) {
      throw new Error(`获取用户信息失败[${res.data.errcode}]: ${res.data.errmsg}`);
    }

    return res.data;
  } catch (err) {
    console.error('[WechatService] 获取用户信息失败:', err.message);
    throw err;
  }
}

/**
 * 刷新access_token
 * @param {string} refreshToken - 刷新令牌
 * @returns {Promise<Object>} { access_token, expires_in, refresh_token, openid, scope }
 */
async function refreshAccessToken(refreshToken) {
  // MVP Mock模式
  if (isMockMode()) {
    console.log('[WechatService] Mock模式：模拟刷新token');
    return {
      access_token: 'mock_access_token_refreshed_' + Date.now(),
      expires_in: 7200,
      refresh_token: 'mock_refresh_token_refreshed_' + Date.now(),
      openid: MOCK_TOKEN_DATA.openid,
      scope: 'snsapi_userinfo'
    };
  }

  try {
    const res = await axios.get(WECHAT_API.REFRESH_TOKEN, {
      params: {
        appid: config.wechat.appId,
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      }
    });

    if (res.data.errcode) {
      throw new Error(`刷新token失败[${res.data.errcode}]: ${res.data.errmsg}`);
    }

    return res.data;
  } catch (err) {
    console.error('[WechatService] 刷新access_token失败:', err.message);
    throw err;
  }
}

/**
 * 验证access_token是否有效
 * @param {string} accessToken - 访问令牌
 * @param {string} openid - 用户OpenID
 * @returns {Promise<boolean>} 是否有效
 */
async function verifyAccessToken(accessToken, openid) {
  // MVP Mock模式
  if (isMockMode()) {
    return true;
  }

  try {
    const res = await axios.get(WECHAT_API.VERIFY_TOKEN, {
      params: {
        access_token: accessToken,
        openid
      }
    });

    return res.data.errcode === 0;
  } catch (err) {
    console.error('[WechatService] 验证access_token失败:', err.message);
    return false;
  }
}

module.exports = {
  getAccessToken,
  getUserInfo,
  refreshAccessToken,
  verifyAccessToken
};
