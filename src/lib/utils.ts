import type { ClassValue } from 'clsx';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type WithoutChild<T> = T extends { child?: any } ? Omit<T, 'child'> : T;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type WithoutChildren<T> = T extends { children?: any } ? Omit<T, 'children'> : T;
export type WithoutChildrenOrChild<T> = WithoutChildren<WithoutChild<T>>;
export type WithElementRef<T, U extends HTMLElement = HTMLElement> = T & { ref?: U | null };

export async function attempt<T, E = Error>(
	func: (() => T) | Promise<T>,
	handler?: ((error: E) => void) | 'throw'
): Promise<{ result: T | null; error: E | null }> {
	try {
		const result = await (func instanceof Promise ? func : Promise.resolve().then(func));
		return { result, error: null };
	} catch (error) {
		if (handler === 'throw') {
			throw error;
		}
		if (handler) {
			handler(error as E);
		}

		return { result: null, error: error as E };
	}
}

export function delay(ms: number) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}
