import CategoryList from '@/views/Category/List.vue';
import CreateCategory from '@/views/Category/Create.vue';

export enum CategoryRouteName {
  CATEGORY_LIST = 'CategoryList',
  CREATE_CATEGORY = 'CreateCategory',
}

export const categoryRoutes = [
  {
    path: '/category',
    name: CategoryRouteName.CATEGORY_LIST,
    component: CategoryList,
    meta: { requiredAuth: false },
  },
  {
    path: '/category/create',
    name: CategoryRouteName.CREATE_CATEGORY,
    component: CreateCategory,
    meta: { requiredAuth: true },
  },
];
