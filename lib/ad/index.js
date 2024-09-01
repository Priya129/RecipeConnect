const express = require('express');
const app = express();
const Stripe = require('stripe');
const cors = require('cors');
require('dotenv').config();

const stripe = Stripe('sk_test_51PpRH6L7dY78ZxcIVW00yeLPPk7CUPfPybcDiijtYsgMaHyJPjvKJim1PTAZ295WJjXrLt8E4FSHwBQn0iw9z0Km00JRRs1X9N'); 

app.use(cors());
app.use(express.json());

// Create a Payment Intent
app.post('/create-payment-intent', async (req, res) => {
    const { amount, currency, paymentMethodId, customerId } = req.body;

    try {
        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency,
            payment_method: paymentMethodId,
            customer: customerId,
            confirmation_method: 'automatic',
            confirm: true,
        });

        res.send({
            success: true,
            paymentIntent,
        });
    } catch (error) {
        res.send({
            success: false,
            error: error.message,
        });
    }
});

// Create a Customer and Save Payment Method
app.post('/create-customer', async (req, res) => {
    const { email, paymentMethodId } = req.body;

    try {
        const customer = await stripe.customers.create({
            email,
            payment_method: paymentMethodId,
            invoice_settings: {
                default_payment_method: paymentMethodId,
            },
        });

        res.send({
            success: true,
            customer,
        });
    } catch (error) {
        res.send({
            success: false,
            error: error.message,
        });
    }
});

// List Saved Payment Methods
app.post('/list-payment-methods', async (req, res) => {
    const { customerId } = req.body;

    try {
        const paymentMethods = await stripe.paymentMethods.list({
            customer: customerId,
            type: 'card',
        });

        res.send({
            success: true,
            paymentMethods: paymentMethods.data,
        });
    } catch (error) {
        res.send({
            success: false,
            error: error.message,
        });
    }
});

app.listen(4242, () => console.log('Server running on port 4242'));
