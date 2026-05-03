<script setup>
import { Head } from '@inertiajs/vue3';
import HomeHeader from '@/Components/HomeHeader.vue';
import HomeHero from '@/Components/HomeHero.vue';
import HomeFeatures from '@/Components/HomeFeatures.vue';
import HomeCTA from '@/Components/HomeCTA.vue';
import HomeFooter from '@/Components/HomeFooter.vue';

defineProps({
    canLogin: {
        type: Boolean,
    },
    canRegister: {
        type: Boolean,
    },
});
</script>

<template>
    <Head title="Welcome" />

    <div class="min-h-screen bg-gray-50">
        <HomeHeader :can-login="canLogin" :can-register="canRegister" />
        <HomeHero />
        <HomeFeatures />
        <HomeCTA />
        <HomeFooter />
    </div>
</template>
