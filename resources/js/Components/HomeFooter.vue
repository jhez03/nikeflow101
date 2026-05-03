<script setup>
import { Link } from '@inertiajs/vue3';

const links = [
    { label: 'About', href: '#' },
    { label: 'Contact', href: '#' },
    { label: 'Privacy', href: '#' },
    { label: 'Terms', href: '#' },
];
</script>

<template>
    <footer class="border-t border-gray-200 bg-white">
        <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
            <div class="flex flex-col items-center gap-4 sm:flex-row sm:justify-between">
                <p class="text-sm text-gray-500">
                    &copy; {{ new Date().getFullYear() }} Nikeflow. All rights reserved.
                </p>

                <nav class="flex items-center gap-6">
                    <Link
                        v-for="link in links"
                        :key="link.label"
                        :href="link.href"
                        class="text-sm text-gray-500 transition hover:text-gray-900"
                    >
                        {{ link.label }}
                    </Link>
                </nav>
            </div>
        </div>
    </footer>
</template>
