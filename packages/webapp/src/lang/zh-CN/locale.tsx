// @ts-nocheck
import printValue from '../printValue';

export const locale = {
  mixed: {
    default: '${path} 无效',
    required: '${path} 为必填字段',
    oneOf: '${path} 必须是以下值之一：${values}',
    notOneOf: '${path} 不能是以下值之一：${values}',
    notType: ({ path, type, value, originalValue }) => {
      let isCast = originalValue != null && originalValue !== value;
      let msg =
        `${path} 必须是 \`${type}\` 类型，` +
        `但最终值为：\`${printValue(value, true)}\`` +
        (isCast
          ? ` (从值 \`${printValue(originalValue, true)}\` 转换而来).`
          : '.');

      if (value === null) {
        msg += `\n 如果 "null" 表示空值，请确保将 schema 标记为 \`.nullable()\``;
      }

      return msg;
    },
    defined: '${path} 必须已定义',
  },
  string: {
    length: '${path} 必须恰好为 ${length} 个字符',
    min: '${path} 至少需要 ${min} 个字符',
    max: '${path} 最多只能有 ${max} 个字符',
    matches: '${path} 必须匹配以下格式："${regex}"',
    email: '${path} 必须是有效的邮箱地址',
    url: '${path} 必须是有效的 URL',
    trim: '${path} 不能包含首尾空格',
    lowercase: '${path} 必须是小写字符串',
    uppercase: '${path} 必须是大写字符串',
  },
  number: {
    min: '${path} 必须大于或等于 ${min}',
    max: '${path} 必须小于或等于 ${max}',
    lessThan: '${path} 必须小于 ${less}',
    moreThan: '${path} 必须大于 ${more}',
    notEqual: '${path} 不能等于 ${notEqual}',
    positive: '${path} 必须为正数',
    negative: '${path} 必须为负数',
    integer: '${path} 必须为整数',
  },
  date: {
    min: '${path} 字段必须晚于 ${min}',
    max: '${path} 字段必须早于 ${max}',
  },
  boolean: {},
  object: {
    noUnknown:
      '${path} 字段不能包含未在对象形状中指定的键',
  },
  array: {
    min: '${path} 字段至少需要 ${min} 个项目',
    max: '${path} 字段最多只能有 ${max} 个项目',
  },
};
