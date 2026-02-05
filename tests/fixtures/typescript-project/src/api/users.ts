/**
 * User API endpoints.
 * Handles CRUD operations for user management.
 */

export interface User {
  id: string;
  name: string;
  email: string;
}

export function getUsers(): User[] {
  return [];
}

export function createUser(data: Omit<User, 'id'>): User {
  return { id: '1', ...data };
}
