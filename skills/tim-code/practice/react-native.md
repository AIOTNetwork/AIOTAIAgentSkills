# Do ⭕

1.  Should use typescript on all possible files
2.  Should follow functional components arhitecture
3.  Should use stylesheet api like flexbox, positioning on layout
4.  Should use figma [design tokens](../design/DESIGN_TOKENS.md) on stlying
5.  Should use react-query & axios on any api calling
6.  Should use zustand for any cross components state management
7.  Should use enums for domain constants (e.g. "enum Fruit { Apple = 0 , Banana = 1 }")
8.  Should use svg if possible
9.  Should use react-hook-form with zod for form validation
10. Should use hooks in react cycle, utils out of react cycle
11. Should reuse value that using multiple times
12. Should provide i18n for all text you added (en / ms / zh-TW / zh-CN)
13. Should avoid calling any deprecated method
14. Should reach axios layer only under src/apis
15. Should use hex color code instead of rgba color code
16. Should use dayjs for datetime formatting
17. Should use "interface" for object like typing
18. Should use "type" for primitive , dynamic , generic typing

# Don't ❌

1. Avoid "any" on typing
2. Avoid comment unless it is critical
3. Avoid printing log on code while not debugging
4. Avoid using console.log (use info / warn / error)

# Naming

1. component = Hello.tsx
2. hook = useHello.ts
3. others = hello.ts

# Structure 🔑

```bash
.
├── App.tsx                         # entry point
├── src/
│   ├── apis/
│   │   └── accounts/               # module
│   │       ├── getAccount.ts       # api
│   │       └── login.ts            # api
│   ├── components/
│   │   ├── accounts/
│   │   │   └── Register.tsx        # component
│   │   └── commons/
│   │       └── Input.tsx           # reusable component
│   ├── constants/
│   │   └── accounts/
│   │       └── account.ts          # enum / constant
│   ├── declarations/
│   │   └── commons/
│   │       └── image.d.ts          # declarations
│   ├── hooks/
│   │   └── accounts/
│   │       └── useAccount.ts       # react util logic
│   ├── schemas/
│   │   └── commons/
│   │       └── email.ts            # zod schema (form response)
│   ├── screens/
│   │   └── accounts/
│   │       └── LoginScreen.tsx     # screen / page
│   ├── stores/
│   │   └── accounts/
│   │       └── useAuthStore.ts     # zustand store
│   ├── transfrom/
│   │   └── accounts/
│   │       └── account.ts          # zod schema (transform BE response to FE entity)
│   ├── types/
│   │   └── accounts/
│   │       └── account.ts          # type / interface
│   ├── utils/
│   │   └── accounts/
│   │       └── account.ts          # util logic
└── assets/                         # images
```

# Sample 🔑

@api/books/getBook.ts

```ts
import { ApiResponse } from "@/types/commons/response.ts";
import { bookTransformSchema } from "@/transforms/books/book.ts";

interface Data {
  id: string;
  name: string;
}

type Response = ApiResponse<Data>;

interface Request {
  id: string;
}

const API_PATH = "/books";

const getBook = (request: Request) => {
  const { id } = request;
  return {
    queryKey: ["book", id],
    queryFn: async () => {
      const response = (await axios.get(`${API_PATH}/${id}`)) as Response;
      return bookTransformSchema.parse(response.data);
    },
  };
};

export default getBook;
```

@components/books/BookList.tsx

```tsx
import { StyleSheet, View, ActivityIndicator, Text } from "react-native";
import { FlashList } from "@shopify/flash-list";
import { useQuery } from "@tanstack/react-query";
import { designTokens } from "@/constants/designTokens";
import { useTranslation } from "@/hooks/commons/useTranslation";
import getBooks from "@/apis/books/getBooks";
import BookCard from "@/components/books/BookCard";

import getBooks from "@/api/books/getBooks.ts";

export const BookList = () => {
  const { data: books, isLoading, isError } = useQuery(getBooks());
  const { t } = useTranslation();

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator style={styles.indicator} />
      </View>
    );
  }

  if (isError) {
    return (
      <View style={styles.center}>
        <Text>{t("book.fail_to_load")}</Text>
      </View>
    );
  }

  return (
    <FlashList
      data={books}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <BookCard book={item} />}
      estimatedItemSize={80}
    />
  );
};

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  indicator: {
    color: designTokens.colors.brand.tiffany,
  },
});

export default BookList;
```

# Comment 🔑

Should use [better comments](https://marketplace.visualstudio.com/items?itemName=aaron-bond.better-comments) format:

1. only use [// todo]() , [// \*]()
2. prefer description in lower case

```bash
# example

// todo >> {task}
// * >> {explain}
```
