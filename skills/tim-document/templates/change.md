# File > `packages/lib-share/types/auth.ts` 🔑

(1) extend `LoginRequest` to include captcha fields

```typescript
export interface LoginRequest {
  username: string;
  password: string;
  captcha: string;
  uuid: string;
  deviceId: string;
  tenantCode?: string;
  userKey: string;
}
```

# File > `packages/lib-share/apis/auth/getCaptcha.ts` 🔑 (new)

(1) create reusable captcha helper — builds captcha image URL and verifies it is reachable

```typescript
const API_URL = process.env.NEXT_PUBLIC_APP_API;

export const getCaptchaUrl = async (): Promise<{
  url: string;
  uuid: string;
} | null> => {
  const uuid = crypto.randomUUID();
  const url = `${API_URL}sys/auth/captcha?uuid=${uuid}`;
  // HEAD then GET fallback to verify url is reachable
  // return { url, uuid } if ok, null if not
};
```

# File > `apps/broker/components/login/LoginForm.tsx` 🔑

(1) add captcha state: `uuid`, `captchaUrl`, `captchaError`

```typescript
const [uuid, setUuid] = useState("");
const [captchaUrl, setCaptchaUrl] = useState("");
const [captchaError, setCaptchaError] = useState(false);
```

(2) add `refreshCaptcha` function — calls `getCaptchaUrl()` from lib-share, updates uuid + captchaUrl state

(3) call `refreshCaptcha` on mount via `useEffect`

(4) add captcha input field + captcha image in the form (between password and submit button)

- text input for captcha code (name="captcha")
- clickable captcha image that refreshes on click
- fallback loading spinner when captcha fails to load

(5) update `handleSubmit` to include all fields from `LoginRequest`:

- `captcha` from form input
- `uuid` from state
- `deviceId` from localStorage (`CacheKey.DeviceId`)
- `tenantCode` from localStorage (`CacheKey.TenantCode`)
- `userKey` computed via md5 signature (`md5(userKey + uuid + username)`)

(6) on login error, refresh captcha image

# File `apps/broker/messages/en.json` 🔑 (+ zhcn.json, zhhk.json)

(1) add i18n keys for captcha

```json
{
  "login": {
    "captcha": "Captcha",
    "captcha_placeholder": "Enter captcha"
  }
}
```

# File > `packages/lib-share/constants/cacheKey.ts` 🔑

(1) verify existing keys — `DeviceId`, `UserKey`, `TenantCode` already exist ✓ no changes needed
