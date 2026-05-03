<script setup>
import { Link } from '@inertiajs/vue3';
import ApplicationLogo from '@/Components/ApplicationLogo.vue';

defineProps({
    canLogin: Boolean,
    canRegister: Boolean,
});
</script>

<template>
    <header class="sticky top-0 z-50 border-b border-gray-200 bg-white">
        <div class="mx-auto flex max-w-7xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
            <Link href="/" class="flex items-center gap-2">
                <ApplicationLogo class="h-8 w-8 fill-current text-gray-800" />
                <span class="text-lg font-semibold text-gray-800">Nikeflow</span>
            </Link>

            <nav v-if="canLogin" class="flex items-center gap-4">
                <Link
                    :href="route('login')"
                    class="rounded-md px-4 py-2 text-sm font-medium text-gray-700 transition hover:text-gray-900"
                >
                    Log in
                </Link>

                <Link
                    v-if="canRegister"
                    :href="route('register')"
                    class="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-gray-800"
                >
                    Register
                </Link>
            </nav>
        </div>
    </header>
</template>
