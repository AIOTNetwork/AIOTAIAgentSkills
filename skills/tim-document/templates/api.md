# GET `sys/auth/captcha` 🔑 (new)

- parameter
  ✓ `uuid: string`
- when
  ✓ on mount
  ✓ on refresh click
  ✓ on login error
- remark
  ✓ in `packages/lib-share/apis/auth/getCaptcha.ts`
  ✓ image endpoint, returns URL + uuid, uses `crypto.randomUUID()`

# POST `sys/auth/login` 🔑

- parameter
  ✓ `username: string`
  ✓ `password: string`
  ✓ `captcha: string`
  ✓ `uuid: string`
  ✓ `deviceId: string`
  ✓ `tenantCode?: string`
  ✓ `userKey: string`
- when
  ✓ on form submit
- remark
  ✓ existing `postLogin` api
  ✓ `LoginRequest` type needs to be extended with: `captcha`, `uuid`, `deviceId`, `tenantCode`, `userKey`
